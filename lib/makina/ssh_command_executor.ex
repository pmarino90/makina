defmodule Makina.SSHCommandExecutor do
  @moduledoc false

  alias Makina.Models.Server
  alias Makina.Infrastructure.SSH
  alias Makina.Infrastructure.RemoteCommand
  alias Makina.Infrastructure.RemoteCommand.Executor

  @behaviour Executor

  @impl true
  def execute(%RemoteCommand{cmd: :connect_to_server, server: server}) do
    case SSH.connect(server.host, user: server.user, password: server.password) do
      {:ok, conn_ref} ->
        Server.put_private(server, :conn_ref, conn_ref)

      _err ->
        raise """
        Could not connect to "#{server.host}".
        """
    end
  end

  def execute(%RemoteCommand{cmd: cmd, server: server} = command) do
    format_response = command.format_response || fn res -> res end

    SSH.cmd(server.__private__.conn_ref, cmd) |> format_response.()
  end
end
