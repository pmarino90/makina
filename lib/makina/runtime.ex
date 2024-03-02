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

  alias Phoenix.PubSub
  alias Makina.Runtime.Instance
  alias Makina.Apps
  alias Makina.Runtime.App

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
    apps = Apps.list_applications()

    Logger.info("Starting Makina Runtime")

    children = [
      {Registry, keys: :unique, name: Makina.Runtime.Registry},
      {Task.Supervisor, name: Makina.Runtime.TaskSupervisor}
    ]

    child_apps =
      for app <- apps do
        build_app_child_spec(app)
      end

    Supervisor.init(children ++ child_apps, strategy: :one_for_one, max_seconds: 30)
  end

  @doc """
  Starts an application given an app definition according to `Makina.Apps.Application`,
  should contain also services.
  """
  def start_app(app) do
    child_spec = build_app_child_spec(app)

    case Supervisor.start_child(__MODULE__, child_spec) do
      {:error, :already_present} ->
        Supervisor.restart_child(__MODULE__, app_id(app))

      {:ok, _} ->
        :ok
    end

    PubSub.broadcast(Makina.PubSub, "app::#{app.id}", {:app_update, :state, {:running}})
  end

  @doc """
  Stops an app given its ID.

  > #### Supervision tree {: .info}
  >
  > The app is not removed from the tree once stopped.
  """
  def stop_app(id) do
    Supervisor.terminate_child(__MODULE__, app_id(id))
    Supervisor.delete_child(__MODULE__, app_id(id))
    PubSub.broadcast(Makina.PubSub, "app::#{id}", {:app_update, :state, {:stopped}})
  end

  @doc """
  Returns whether the app is running or not.

  The state is determined by cheching whether the Application Supervisor is running for the
  given app `id`
  """
  def app_running?(id) do
    pid = app_pid(id)

    if is_pid(pid), do: Process.alive?(pid), else: false
  end

  def app_state(id) do
    if app_running?(id), do: :running, else: :stopped
  end

  @doc """
  Given a `service_id` it returns the current status of all the running instances.
  If the consolidated state is needed see `Runtime.get_service_state/2`
  """
  def get_service_state(id) do
    Registry.lookup(Makina.Runtime.Registry, "service-#{id}-instance-1")
    |> Enum.map(fn {pid, _} -> Instance.get_current_state(pid) end)
  end

  @doc """
  Given a `service_id` it returns the current status of all the running instances.

  Accepts additional options:
  * `:consolidated`, returns the consolidated state meaning that if all instances are running
  the returned state is `:running` while if only part of them are the state is `:incosistant`
  """
  def get_service_state(id, opts) do
    unless Keyword.get(opts, :consolidated),
      do: raise("Invalid options provided, only `:consolidate` supported.")

    states =
      get_service_state(id)
      |> Enum.uniq()

    count = Enum.count(states)

    cond do
      count == 1 -> hd(states)
      count > 1 -> :inconsistant
      count < 1 -> :no_service
    end
  end

  @doc """
  Stops the runtime

  All the running applications and services are stopped as well.
  """
  def stop(), do: Supervisor.stop(__MODULE__)

  defp build_app_child_spec(app) do
    %{start: {App, :start_link, [app_spec: app]}, id: app_id(app), restart: :transient}
  end

  defp app_pid(app_id) do
    Supervisor.which_children(__MODULE__)
    |> Enum.find_value(fn {id, pid, _, _} ->
      if app_id(app_id) == id, do: pid, else: false
    end)
  end

  defp app_id(id) when is_integer(id), do: "app_#{id}"
  defp app_id(%Apps.Application{} = app), do: "app_#{app.id}"
end
