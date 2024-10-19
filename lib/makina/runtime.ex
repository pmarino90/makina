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

  require Logger

  alias Phoenix.PubSub
  alias Makina.Runtime.Instance
  alias Makina.Stacks
  alias Makina.Runtime.Stack

  @doc """
  Starts an application given an app definition according to `Makina.Stacks.Stack`,
  should contain also services.
  """
  def start_stack(stack) do
    child_spec = build_app_child_spec(stack)

    case Supervisor.start_child(Makina.Runtime.Supervisor, child_spec) do
      {:error, :already_present} ->
        Supervisor.restart_child(Makina.Runtime.Supervisor, app_id(stack))

      {:ok, _} ->
        :ok
    end

    PubSub.broadcast(Makina.PubSub, "stack::#{stack.id}", {:app_update, :state, {:running}})
  end

  @doc """
  Stops an app given its ID.

  > #### Supervision tree {: .info}
  >
  > The app is not removed from the tree once stopped.
  """
  def stop_stack(stack) do
    Supervisor.terminate_child(Makina.Runtime.Supervisor, app_id(stack.id))
    Supervisor.delete_child(Makina.Runtime.Supervisor, app_id(stack.id))
    PubSub.broadcast(Makina.PubSub, "stack::#{stack.id}", {:app_update, :state, {:stopped}})
  end

  @doc """
  Returns whether the app is running or not.

  The state is determined by cheching whether the Stack Supervisor is running for the
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
  def get_service_state(service) do
    Registry.lookup(Makina.Runtime.Registry, "service-#{service.slug}-instance-1")
    |> Enum.map(fn {pid, _} -> Instance.get_current_state(pid) end)
  end

  @doc """
  Given a service service_id` it returns the current status of all the running instances.

  Accepts additional options:
  * `:consolidated`, returns the consolidated state meaning that if all instances are running
  the returned state is `:running` while if only part of them are the state is `:incosistant`
  """
  def get_service_state(service, opts) do
    unless Keyword.get(opts, :consolidated),
      do: raise("Invalid options provided, only `:consolidate` supported.")

    states =
      get_service_state(service)
      |> Enum.uniq()

    count = Enum.count(states)

    cond do
      count == 1 -> hd(states)
      count > 1 -> :inconsistent
      count < 1 -> :no_service
    end
  end

  def start_service(stack, service) do
    stack_supervisor = app_pid(service.application_id)

    Supervisor.start_child(stack_supervisor, Stack.build_child_spec(stack, service))
    |> dbg()
  end

  def stop_service(service) do
    app_supervisor = app_pid(service.application_id)

    Supervisor.terminate_child(app_supervisor, "service_#{service.id}")
    Supervisor.delete_child(app_supervisor, "service_#{service.id}")

    PubSub.broadcast(
      Makina.PubSub,
      "stack::#{service.application_id}",
      {:service_update, :state, {:stopped, service}}
    )
  end

  @doc """
  Stops the runtime

  All the running applications and services are stopped as well.
  """
  def stop(), do: Supervisor.stop(Makina.Runtime.Supervisor)

  defp build_app_child_spec(app) do
    %{start: {Stack, :start_link, [app_spec: app]}, id: app_id(app), restart: :transient}
  end

  defp app_pid(app_id) do
    Supervisor.which_children(Makina.Runtime.Supervisor)
    |> Enum.find_value(fn {id, pid, _, _} ->
      if app_id(app_id) == id, do: pid, else: false
    end)
  end

  defp app_id(id) when is_integer(id), do: "app_#{id}"
  defp app_id(%Stacks.Stack{} = app), do: "app_#{app.id}"
end
