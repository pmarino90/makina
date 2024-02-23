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

  alias Makina.Docker

  # Client

  @doc false
  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  def bootstrap(pid), do: GenServer.cast(pid, :bootstrap)

  # Server

  def init({parent, app, service}) do
    Logger.info("Starting Instance for service #{service.name}")

    Process.flag(:trap_exit, true)
    Process.monitor(parent)

    bootstrap(self())

    {:ok, %{app: app, service: service, instance_number: 1, state: :booting}}
  end

  @doc false
  def terminate(_reason, state) do
    handle_shutdown(state)
  end

  @doc false
  def handle_cast(:bootstrap, state) do
    state
    |> pull_image()
    |> create_container()
    |> start_container()

    {:noreply, %{state | state: :started}}
  end

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

    {:noreply, %{state | state: :stopped}}
  end

  defp pull_image(%{service: service} = state) do
    Docker.pull_image(
      docker: %{
        "fromImage" => "#{service.image_name}:#{service.image_tag}"
      }
    )

    state
  end

  defp create_container(%{service: service} = state) do
    container_name(state)
    |> Docker.create_container(%{
      "Image" => "#{service.image_name}:#{service.image_tag}",
      "Env" => build_env_variables(service)
    })

    state
  end

  defp build_env_variables(service) do
    service.environment_variables
    |> Enum.map(fn e -> "#{e.name}=#{e.value}" end)
  end

  defp start_container(state) do
    container_name(state)
    |> Docker.start_container()

    state
  end

  defp container_name(%{app: app, service: service, instance_number: number}),
    do: "#{app.name}-#{service.name}_#{number}"
end
