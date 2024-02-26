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

  # Client

  def bootstrap(pid), do: GenServer.cast(pid, :bootstrap)

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
  def start_link({_parent, _app_, service} = args),
    do:
      GenServer.start_link(__MODULE__, args,
        name: {:via, Registry, {Makina.Runtime.Registry, "service-#{service.id}-instance-1"}}
      )

  # Server

  def init({parent, app, service}) do
    Logger.info("Starting Instance for service #{service.name}")

    Process.flag(:trap_exit, true)
    Process.monitor(parent)

    bootstrap(self())

    {:ok, %{app: app, service: service, instance_number: 1, running_state: :booting}}
  end

  @doc false
  def terminate(_reason, state) do
    handle_shutdown(state)
  end

  ## Cast

  @doc false
  def handle_cast(:bootstrap, state) do
    state
    |> pull_image()
    |> create_volumes()
    |> create_container()
    |> start_container()
    |> notify_running_state(:running)

    {:noreply, %{state | running_state: :running}}
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

  defp handle_shutdown(state) do
    container_name(state)
    |> Docker.stop_container()

    container_name(state)
    |> Docker.wait_for_container()

    notify_running_state(state, :stopped)

    {:noreply, %{state | running_state: :stopped}}
  end

  defp pull_image(%{service: service} = state) do
    dbg("#{service.image_registry}#{service.image_name}:#{service.image_tag}")

    Docker.pull_image(
      docker: %{
        "fromImage" => "#{service.image_registry}#{service.image_name}:#{service.image_tag}"
      },
      headers: [x_registry_auth: build_auth_header(service)]
    )

    state
  end

  defp create_container(%{service: service} = state) do
    container_name(state)
    |> Docker.create_container(%{
      "Image" => "#{service.image_registry}#{service.image_name}:#{service.image_tag}",
      "Env" => build_env_variables(service),
      "Volumes" => build_docker_volumes_map(service.volumes),
      "HostConfig" => %{
        "Bind" => build_docker_volumes_bind(service.volumes),
        "NetworkMode" => "makina_makina-net"
      },
      "Labels" => build_docker_labels(state)
    })

    state
  end

  defp start_container(state) do
    container_name(state)
    |> Docker.start_container()

    state
  end

  defp create_volumes(state) do
    volumes = state.service.volumes

    if volumes != [] do
      for volume <- volumes do
        Docker.create_volume(volume.name)
      end
    end

    state
  end

  defp build_env_variables(service) do
    service.environment_variables
    |> Enum.map(fn e -> "#{e.name}=#{e.value}" end)
  end

  defp build_docker_volumes_bind(volumes) do
    volumes
    |> Enum.map(fn v -> "#{v.name}:#{v.mount_point}" end)
  end

  defp build_docker_volumes_map(volumes) do
    volumes
    |> Enum.reduce(%{}, fn v, map -> Map.put(map, v.mount_point, %{}) end)
  end

  defp build_docker_labels(%{app: app, service: service}) do
    domain = Map.get(hd(service.domains), :domain) || "example.com"

    labels = %{
      "com.makina.app" => app.name,
      "com.makina.service" => service.name
    }

    if service.expose_service do
      Map.merge(
        labels,
        %{
          "traefik.http.routers.#{app.name}_#{service.name}.rule" => "Host(`#{domain}`)",
          "traefik.http.services.#{app.name}_#{service.name}.loadBalancer.server.port" => "4000"
        }
      )
    else
      labels
    end
  end

  defp notify_running_state(state, new_state) do
    PubSub.broadcast(
      Makina.PubSub,
      "app::#{state.app.id}",
      {:service_update, :state, {new_state, state.service}}
    )
  end

  defp container_name(%{app: app, service: service, instance_number: number}),
    do: "#{app.name}-#{service.name}_#{number}"

  defp build_auth_header(service) do
    auth_obj = %{
      "username" => service.image_registry_user,
      "password" => service.image_registry_unsafe_password,
      "serveraddress" => "https://#{service.image_registry}"
    }

    Base.encode64(Jason.encode!(auth_obj))
  end
end
