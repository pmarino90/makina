defmodule Makina.Infrastructure.RemoteCommand do
  @doc """
  Struct that represents a command to execute on a server.

  A Command Executor  will take this command and execute it on the
  server it contains, returning its result.
  """

  defstruct cmd: nil, server: nil, format_response: nil

  defmacro __using__(_opts) do
    quote do
      alias Makina.Infrastructure.RemoteCommand

      def execute_command(%Makina.Infrastructure.RemoteCommand{} = command) do
        mod = Elixir.Application.get_env(:makina, :remote_command_executor, SSH)

        mod.execute(command)
      end
    end
  end
end
