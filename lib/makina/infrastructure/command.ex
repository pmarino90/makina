defmodule Makina.Infrastructure.RemoteCommand do
  @doc """
  Struct that represents a command to execute on a server.

  A Command Executor  will take this command and execute it on the
  server it contains, returning its result.
  """

  defstruct cmd: nil, server: nil, format_response: nil
end
