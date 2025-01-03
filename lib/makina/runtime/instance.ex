defmodule Makina.Runtime.Instance do
  @moduledoc """
  Behaviour representing a generic instance runtime.

  A instance manages the runtime lifecycle of a service.
  In theory services hold the definition of what kind of program has to be run and its configuration
  then an Instance practically implements that.

  Examples of instance runtime can be a Docker Container. A service defines its configuration while
  Instance runs the given service inside a docker container, keeping track if its state throughout
  its whole lifecycle.
  So this behaviour generalizes all these phases so that multiple implementations can be done.
  """
  require Logger

  alias Makina.Runtime.Instance.State
  alias Makina.Runtime.Instance.Infrastructure

  @doc """
  Before the service starts it can be needed to prepare data.
  At this stage the underlying GenServer is not started yet.
  """
  @callback configure(State.t()) :: State.t()

  @doc """
  Callback run before the start callback is run. This can be a good place where
  to prepare the environment needed by the start callback.
  """
  @callback before_run(State.t()) :: State.t()
  @callback on_run(State.t()) :: State.t()
  @callback after_run(State.t()) :: State.t()

  @callback before_stop(State.t()) :: State.t()
  @callback on_stop(State.t()) :: State.t()
  @callback after_stop(State.t()) :: State.t()

  @optional_callbacks before_run: 1,
                      after_run: 1,
                      before_stop: 1,
                      after_stop: 1

  @doc """
  Defines a unified log entry point.
  This function can both log into Makina's console and also the container's 
  log stream (generally visible from the Web UI.
  """
  defdelegate log(state, entry, opts \\ []), to: Infrastructure

  def assign(%State{} = state, key_value_pairs) do
    assigns = Enum.into(key_value_pairs, %{})

    %State{state | assigns: Map.merge(state.assigns, assigns)}
  end

  @doc """
  Runs a given instance.

  Depending on the actual implementation different things can happen, refer to 
  the Instance's concrete implementation for details.

  Upon running the following callbacks are called: 
  * before_run/1
  * run/1
  * after_run/1

  Different implementation may perform various operations within those callbacks.
  Instance calls them sequentially.
  Instance implementations are required to implement at least `run/1`
  """
  def run(pid), do: GenServer.cast(pid, :run)

  def get_current_state(pid), do: GenServer.call(pid, :get_current_state)

  defmacro __using__(_opts) do
    quote do
      use GenServer

      require Logger

      import Makina.Runtime.Instance

      @behaviour Makina.Runtime.Instance

      alias Makina.Runtime.Instance
      alias Makina.Runtime.Instance.State

      def init({parent_process, stack, service, opts}) do
        port_number = Enum.random(1024..65535)
        auto_boot = Keyword.get(opts, :auto_boot, true)

        Process.flag(:trap_exit, true)
        Process.monitor(parent_process)

        Infrastructure.subscribe_to_service_events(service)

        Logger.info("Starting Instance for service #{service.name}")

        state =
          configure(%State{
            running_state: :preparing,
            stack: stack,
            service: service,
            instance_number: 1,
            running_port: port_number,
            pid: self(),
            auto_boot: auto_boot
          })

        if auto_boot, do: boot(state)

        {:ok, state}
      end

      @doc false
      def start_link({_parent, _app_, service, _opts} = args) do
        GenServer.start_link(__MODULE__, args,
          name: {:via, Registry, {Makina.Runtime.Registry, full_instance_name(service)}}
        )
      end

      @doc false
      def terminate(:shutdown, state) do
        shutdown(state)
      end

      def terminate(_reason, state) do
        Logger.warning("Terminating instance unexpectedly, might restart soon.")

        Infrastructure.publish_running_state(state, :crashed)

        {:noreply, %{state | running_state: :crashed}}
      end

      defp full_instance_name(service), do: "service-#{service.id}-#{service.slug}-instance_1"

      defp update_running_state(%State{} = state, running_state) do
        GenServer.cast(state.pid, {:update_running_state, running_state})

        state
      end

      defp boot(state) do
        before_run_cb =
          if Kernel.function_exported?(__MODULE__, :before_run, 1),
            do: fn state -> apply(__MODULE__, :before_run, [state]) end,
            else: fn state -> state end

        after_run_cb =
          if Kernel.function_exported?(__MODULE__, :after_run, 1),
            do: fn state -> apply(__MODULE__, :after_run, [state]) end,
            else: fn state -> state end

        Task.Supervisor.start_child(Makina.Runtime.TaskSupervisor, fn ->
          state
          |> update_running_state(:starting)
          |> before_run_cb.()
          |> on_run()
          |> after_run_cb.()
          |> update_running_state(:running)
        end)
      end

      defp shutdown(state) do
        log(state, "Shutting down instance")

        state =
          state
          |> update_running_state(:stopping)
          |> on_stop()

        {:noreply, %{state | running_state: :stopped}}
      end

      @doc false
      def handle_info({:EXIT, _pid, :normal}, _state) do
        Logger.warning("Linked process terminated unexpectedly")
        raise "restart"
      end

      def handle_info({:config_update, _section, _service}, state) do
        Logger.info("Config update detected. Restarting service.")

        GenServer.cast(self(), :restart)

        {:noreply, state}
      end

      def handle_info({:redeploy, _section, _service}, state) do
        GenServer.cast(self(), :restart)

        {:noreply, state}
      end

      def handle_cast({:update_running_state, running_state}, state) do
        Infrastructure.publish_running_state(state, running_state)
        {:noreply, %State{state | running_state: running_state}}
      end

      def handle_call({:link, pid}, _from, state) do
        Process.link(pid)

        {:reply, true, state}
      end

      def handle_call(:get_current_state, _from, state) do
        {:reply, state.running_state, state}
      end
    end
  end
end
