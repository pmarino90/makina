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

  def init({parent, service}) do
    Logger.info("Starting Instance for service #{service.name}")

    Process.flag(:trap_exit, true)
    Process.monitor(parent)

    bootstrap(self())

    {:ok, %{service: service, state: :booting}}
  end

  @doc false
  def terminate(_reason, state) do
    handle_shutdown(state.service)

    {:noreply, state}
  end

  @doc false
  def handle_cast(:bootstrap, %{service: service, state: :booting} = state) do
    service
    |> pull_image()
    |> create_container()
    |> start_container()

    {:noreply, %{state | state: :started}}
  end

  @doc false
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    handle_shutdown(state.service)

    {:noreply, state}
  end

  @doc false
  def handle_info({:EXIT, _ref, :process, _pid, _reason}, state) do
    handle_shutdown(state.service)

    {:noreply, state}
  end

  defp handle_shutdown(service) do
    Docker.stop_container(service.name)

    service
  end

  defp pull_image(service) do
    Docker.pull_image(
      docker: %{
        "fromImage" => "#{service.image_name}:#{service.image_tag}"
      }
    )

    service
  end

  defp create_container(service) do
    Docker.create_container(service.name, %{
      "Image" => "#{service.image_name}:#{service.image_tag}",
      "Cmd" => ["/bin/sh", "-c", "while true; do echo hello world; sleep 1; done"]
    })

    service
  end

  defp start_container(service) do
    Docker.start_container(service.name)

    service
  end
end
