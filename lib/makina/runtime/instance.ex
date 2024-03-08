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

  alias ElixirSense.Core.Struct
  alias Phoenix.PubSub
  alias Makina.{Apps, Docker, Vault}

  # Client

  def prepare(pid), do: GenServer.cast(pid, :prepare)

  def bootstrap(pid), do: GenServer.cast(pid, :bootstrap)

  def redeploy(pid), do: GenServer.cast(pid, :redeploy)

  def continue(pid), do: GenServer.cast(pid, :continue)

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

  ### Boot sequence
  # On its own the boot sequence is a series of cast to the instance, each handling an
  # individual piece.

  def handle_cast(:prepare, state) do
    GenServer.cast(self(), :continue)

    {:noreply, %{state | running_state: :preparing}}
  end

  def handle_cast(:pull_image, state) do
    log(state, "Pulling image...")

    state =
      state
      |> pull_image()
      |> maybe_detect_exposed_port()

    {:noreply, %{state | running_state: :image_pull}}
  end

  def handle_cast(:create_app_network, state) do
    log(state, "Creating network...")

    state
    |> create_app_network()

    continue(self())

    {:noreply, %{state | running_state: :network_create}}
  end

  def handle_cast(:create_container, state) do
    log(state, "Creating container...")

    state
    |> create_container()

    continue(self())

    {:noreply, %{state | running_state: :container_create}}
  end

  def handle_cast(:network_connect_web, state) do
    log(state, "Connecting container to web network...")

    state
    |> connect_to_web_network()

    continue(self())

    {:noreply, %{state | running_state: :network_web_connect}}
  end

  @doc false
  def handle_cast(:bootstrap, state) do
    log(state, "Starting container...")

    state
    |> start_container()
    |> collect_logs()
    |> notify_running_state(:running)

    continue(self())

    {:noreply, %{state | running_state: :running}}
  end

  def handle_cast(:redeploy, state) do
    state =
      state
      |> mark_container_as_stale()

    Process.exit(self(), :redeploy)

    {:noreply, %{state | running_state: :shutting_down}}
  end

  def handle_cast(:continue, %{running_state: :preparing} = state) do
    GenServer.cast(self(), :pull_image)

    {:noreply, state}
  end

  def handle_cast(:continue, %{running_state: :image_pull} = state) do
    GenServer.cast(self(), :create_app_network)

    {:noreply, state}
  end

  def handle_cast(:continue, %{running_state: :network_create} = state) do
    GenServer.cast(self(), :create_container)

    {:noreply, state}
  end

  def handle_cast(:continue, %{running_state: :container_create} = state) do
    GenServer.cast(self(), :network_connect_web)

    {:noreply, state}
  end

  def handle_cast(:continue, %{running_state: :network_web_connect, auto_boot: true} = state) do
    GenServer.cast(self(), :bootstrap)

    {:noreply, state}
  end

  def handle_cast(:continue, %{running_state: :network_web_connect, auto_boot: false} = state) do
    {:noreply, %{state | running_state: :prepared}}
  end

  def handle_cast(:continue, state) do
    {:noreply, state}
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
  def handle_info({:EXIT, _pid, :normal}, _state) do
    Logger.warning("Log collect Task terminatad, attached container may not be available.")
    raise "Attached container crashed or has been terminated unexpectedly"
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

  def handle_info({:redeploy, _section, _service}, state) do
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
    progress_update = fn {:data, data}, {req, res} ->
      log(state, data, with_prompt: false)

      {:cont, {req, res}}
    end

    params = [
      docker: %{
        "fromImage" => full_image_reference(service)
      },
      on_progress: progress_update
    ]

    params =
      if service.image_registry_user,
        do: Keyword.put(params, :headers, x_registry_auth: build_auth_header(service)),
        else: params

    Task.Supervisor.start_child(Makina.Runtime.TaskSupervisor, fn ->
      [instance_pid] = Process.get(:"$callers")

      Docker.pull_image(params)
      GenServer.cast(instance_pid, :continue)
    end)

    state
  end

  defp maybe_detect_exposed_port(%{service: service} = state) do
    image_info =
      full_image_reference(service)
      |> Docker.inspect_image()

    exposed_ports =
      image_info.body
      |> get_in(["Config", "ExposedPorts"])

    if exposed_ports != nil do
      ports =
        exposed_ports
        |> Map.keys()
        |> Enum.map(fn port_and_proto ->
          [port, _proto] = String.split(port_and_proto, "/")

          port
        end)

      %{state | running_port: hd(ports)}
    else
      state
    end
  end

  defp create_container(%{app: app, service: service} = state) do
    Logger.info("Creating container #{state.container_name}")

    state.container_name
    |> Docker.create_container(%{
      "Image" => full_image_reference(service),
      "Env" => build_env_variables(state),
      "Tty" => true,
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
      |> Enum.map(fn e -> "#{e.name}=#{get_env_variable_value(e)}" end)

    if service.expose_service do
      ["PORT=#{port}"] ++ vars
    else
      vars
    end
  end

  defp get_env_variable_value(var) do
    case var.type do
      :secret -> Vault.decrypt!(var.encrypted_value)
      _ -> var.text_value
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
      "password" => Vault.decrypt!(service.image_registry_encrypted_password),
      "serveraddress" => "https://#{service.image_registry}"
    }

    Base.encode64(Jason.encode!(auth_obj))
  end

  defp collect_logs(state) do
    entry_collector = fn {:data, data}, {req, res} ->
      log(state, data, with_prompt: false)

      {:cont, {req, res}}
    end

    {:ok, pid} =
      Task.Supervisor.start_child(Makina.Runtime.TaskSupervisor, fn ->
        Docker.logs_for_container(state.container_name, entry_collector)
      end)

    Process.link(pid)

    state
  end

  defp log(state, entry, opts \\ []) do
    with_prompt = Keyword.get(opts, :with_prompt, true)

    entry = if with_prompt, do: format_log_with_prompt(entry), else: entry

    PubSub.broadcast(
      Makina.PubSub,
      "system::service::#{state.service.id}::logs",
      {:log_entry, IO.chardata_to_string(entry)}
    )
  end

  defp format_log_with_prompt(entry) do
    IO.ANSI.format([
      :cyan,
      :bright,
      "[Makina][InstanceRunner]",
      " ",
      entry,
      "\n\r"
    ])
  end
end
