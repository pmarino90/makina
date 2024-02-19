defmodule Makina.Runtime do
  @moduledoc """
  Main interface with the app Runtime.

  In practice the runtime is a Supervisor, starting all defined apps.
  * Each app has one or more services building it
  * Each service may have more than one instance

  When the Runtime boots it starts all the app as children. New apps can be then
  added at runtime as well.

  When the Runtime is shutdown all apps are shutdown as well.
  """

  use Supervisor
  require Logger

  alias Makina.Apps
  alias Makina.Runtime.App

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def child_spec(_init_arg) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [{}]}, restart: :transient}
  end

  def init(_init_args) do
    apps = Apps.list_applications()

    Logger.info("Starting Makina Runtime")

    children =
      for app <- apps do
        build_app_child_spec(app)
      end

    Supervisor.init(children, strategy: :one_for_one, max_seconds: 30)
  end

  def start_app(app) do
    child_spec = build_app_child_spec(app)

    case Supervisor.start_child(__MODULE__, child_spec) do
      {:error, :already_present} -> Supervisor.restart_child(__MODULE__, app_id(app))
    end
  end

  def stop_app(id), do: Supervisor.terminate_child(__MODULE__, app_id(id))

  def stop(), do: Supervisor.stop(__MODULE__)

  defp build_app_child_spec(app) do
    %{start: {App, :start_link, [app_spec: app]}, id: app_id(app), restart: :transient}
  end

  defp app_id(id) when is_integer(id), do: "app_#{id}"
  defp app_id(%Apps.Application{} = app), do: "app_#{app.id}"
end