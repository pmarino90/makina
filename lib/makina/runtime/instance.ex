defmodule Makina.Runtime.Instance do
  @moduledoc """
  This module represent a running instance for a given service.
  It is the only responsible for effectively running, updating and monitoring
  the state of a service instance independently from the underlying runtime context.

  In this implementation a service instance is run as a Docker container, meaning
  that each container can be an instance of the given service.
  """
  use GenServer

  require Logger

  alias Phoenix.PubSub
  alias Makina.Docker
  alias Makina.Apps

  # Client

  def prepare(pid), do: GenServer.cast(pid, :prepare)

  def bootstrap(pid), do: GenServer.cast(pid, :bootstrap)

  def redeploy(pid), do: GenServer.cast(pid, :redeploy)

  @doc """
  Given an instance PID it returns it's current running state.
  The state should reprensent what the current state is in the underlying runtime,
  so `:running` means that the underlying container is up and running.

  These are the possible states:
  * `:booting`, instance is starting up
  * `:running`, instance is running, meaning the underlying container is running.
  * `:stopped`, instance has been gracefully stopped
  """
  def get_current_state(pid), do: GenServer.call(pid, :current_state)

  @doc false
  def start_link({_parent, _app_, service_id, _opts} = args),
    do:
      GenServer.start_link(__MODULE__, args,
        name: {:via, Registry, {Makina.Runtime.Registry, "service-#{service_id}-instance-1"}}
      )

  # Server

  def init({parent, app_id, service_id, opts}) do
    app = Apps.get_app!(app_id)
    service = Apps.get_service!(service_id)
    port_number = Enum.random(1024..65535)
    auto_boot = Keyword.get(opts, :auto_boot, true)

    Process.flag(:trap_exit, true)
    Process.monitor(parent)

    PubSub.subscribe(Makina.PubSub, "system::service::#{service.id}")

    Logger.info("Starting Instance for service #{service.name}")

    prepare(self())

    {:ok,
     %{
       app: app,
       service: service,
       instance_number: 1,
       running_port: port_number,
       running_state: :preparing,
       auto_boot: auto_boot,
       container_name: "#{full_service_name(%{app: app, service: service})}-1"
     }}
  end

  @doc false
  def terminate(_reason, state) do
    handle_shutdown(state)
  end

  ## Cast

  def handle_cast(:prepare, state) do
    state
    |> pull_image()
    |> create_app_network()
    |> create_container()
    |> connect_to_web_network()

    if state.auto_boot, do: bootstrap(self())

    {:noreply, %{state | running_state: :prepared}}
  end

  @doc false
  def handle_cast(:bootstrap, state) do
    state
    |> start_container()
    |> notify_running_state(:running)

    {:noreply, %{state | running_state: :running}}
  end

  def handle_cast(:redeploy, state) do
    state =
      state
      |> mark_container_as_stale()

    Process.exit(self(), :redeploy)

    {:noreply, %{state | running_state: :shutting_down}}
  end

  ## Calls

  def handle_call(:current_state, _from, state) do
    {:reply, state.running_state, state}
  end

  ## Other Messages

  @doc false
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    handle_shutdown(state)
  end

  @doc false
  def handle_info({:EXIT, _ref, :process, _pid, _reason}, state) do
    handle_shutdown(state)
  end

  @doc false
  def handle_info({:EXIT, _ref, :redeploy}, state) do
    handle_shutdown(state)

    raise "Redeploy."
  end

  def handle_info({:config_update, _section, _service}, state) do
    Logger.info("Config update detected. Restarting service.")

    redeploy(self())

    {:noreply, state}
  end

  defp handle_shutdown(state) do
    Docker.stop_container(state.container_name)
    Docker.wait_for_container(state.container_name)
    Docker.remove_container(state.container_name)

    notify_running_state(state, :stopped)

    {:noreply, %{state | running_state: :stopped}}
  end

  defp pull_image(%{service: service} = state) do
    params = [
      docker: %{
        "fromImage" => full_image_reference(service)
      }
    ]

    params =
      if service.image_registry_user,
        do: Keyword.put(params, :headers, x_registry_auth: build_auth_header(service)),
        else: params

    Docker.pull_image(params)

    state
  end

  defp create_container(%{app: app, service: service} = state) do
    Logger.info("Creating container #{state.container_name}")

    state.container_name
    |> Docker.create_container(%{
      "Image" => full_image_reference(service),
      "Env" => build_env_variables(state),
      "HostConfig" => %{
        "Mounts" => build_docker_volumes_mount(state),
        "NetworkMode" => "#{app.slug}-network"
      },
      "Labels" => build_docker_labels(state)
    })

    state
  end

  defp start_container(state) do
    Logger.info("Starting container #{state.container_name}")

    state.container_name
    |> Docker.start_container()

    state
  end

  defp mark_container_as_stale(state) do
    name = state.container_name
    stale_name = "#{name}_stale"

    name
    |> Docker.rename_container(stale_name)

    %{state | container_name: stale_name}
  end

  defp create_app_network(%{app: app} = state) do
    network_name = "#{app.slug}-network"

    res = Docker.inspect_network(network_name)

    if res.status == 200 do
      state
    else
      Docker.create_network(network_name)
      state
    end
  end

  defp connect_to_web_network(%{service: service} = state) do
    if service.expose_service do
      Docker.connect_network(state.container_name, "makina_web-net")
      state
    else
      state
    end
  end

  defp build_env_variables(%{service: service, running_port: port}) do
    vars =
      service.environment_variables
      |> Enum.map(fn e -> "#{e.name}=#{e.value}" end)

    if service.expose_service do
      ["PORT=#{port}"] ++ vars
    else
      vars
    end
  end

  defp build_docker_volumes_mount(state) do
    app = state.app
    service = state.service

    service.volumes
    |> Enum.map(fn v ->
      %{
        "Target" => v.mount_point,
        "Source" => "#{app.slug}-#{service.slug}-#{v.name}",
        "Type" => "volume",
        "ReadOnly" => false
      }
    end)
  end

  defp build_docker_labels(%{app: app, service: service} = state) do
    labels = %{
      "com.makina.app" => app.slug,
      "com.makina.service" => service.slug
    }

    {labels, state}
    |> maybe_put_traefik_basic_labels()
    |> maybe_put_https_labels()
    |> elem(0)
  end

  defp maybe_put_traefik_basic_labels({labels, state}) do
    service = state.service

    if service.expose_service do
      domains =
        service.domains
        |> Enum.map(fn d -> "`#{d.domain}`" end)
        |> Enum.join(",")

      labels =
        Map.merge(
          labels,
          %{
            "traefik.enable" => "true",
            "traefik.http.middlewares.#{full_service_name(state)}.compress" => "true",
            "traefik.http.routers.#{full_service_name(state)}.rule" => "Host(#{domains})",
            "traefik.http.services.#{full_service_name(state)}.loadBalancer.server.port" =>
              "#{state.running_port}"
          }
        )

      {labels, state}
    else
      {labels, state}
    end
  end

  defp maybe_put_https_labels({labels, state}) do
    service = state.service
    config = Application.get_env(:makina, Makina.Runtime)

    if service.expose_service and Keyword.get(config, :enable_https, false) do
      labels =
        Map.put(
          labels,
          "traefik.http.routers.#{full_service_name(state)}.tls.certresolver",
          "letsencrypt"
        )

      {labels, state}
    else
      {labels, state}
    end
  end

  defp notify_running_state(state, new_state) do
    PubSub.broadcast(
      Makina.PubSub,
      "app::#{state.app.id}",
      {:service_update, :state, {new_state, state.service}}
    )
  end

  defp full_image_reference(service) do
    registry_host =
      if service.image_registry == "hub.docker.com", do: "", else: "#{service.image_registry}/"

    "#{registry_host}#{service.image_name}:#{service.image_tag}"
  end

  defp full_service_name(%{app: app, service: service}), do: "#{app.slug}-#{service.slug}"

  defp build_auth_header(service) do
    auth_obj = %{
      "username" => service.image_registry_user,
      "password" => service.image_registry_unsafe_password,
      "serveraddress" => "https://#{service.image_registry}"
    }

    Base.encode64(Jason.encode!(auth_obj))
  end
end
