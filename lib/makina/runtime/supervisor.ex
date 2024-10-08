defmodule Makina.Runtime.Supervisor do
  use Supervisor
  require Logger

  alias Makina.Runtime.{Stack, SupportServices}
  alias Makina.Stacks
  alias Makina.Docker

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc false
  def child_spec(_init_arg) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [{}]}, restart: :transient}
  end

  @doc false
  def init(_init_args) do
    apps = Stacks.list_applications()

    Logger.info("Starting Makina Runtime")

    case validate_system_depencencies() do
      {:error, err} -> raise "Cannot start, system not configured #{err}"
      _ -> :ok
    end

    children = [
      {Registry, keys: :unique, name: Makina.Runtime.Registry},
      {Task.Supervisor, name: Makina.Runtime.TaskSupervisor},
      {SupportServices, name: Makina.Runtime.SupportServices}
    ]

    child_apps =
      for app <- apps do
        build_app_child_spec(app)
      end

    Supervisor.init(children ++ child_apps, strategy: :one_for_one, max_seconds: 30)
  end

  defp validate_system_depencencies() do
    case Docker.ping() do
      {:ok, _} -> :ok
      _ -> {:error, :no_docker_service}
    end
  end

  defp build_app_child_spec(app) do
    %{start: {Stack, :start_link, [app_spec: app]}, id: app_id(app), restart: :transient}
  end

  defp app_id(id) when is_integer(id), do: "app_#{id}"
  defp app_id(%Stacks.Stack{} = app), do: "app_#{app.id}"
end
