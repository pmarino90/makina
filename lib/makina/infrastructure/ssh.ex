defmodule Makina.Infrastructure.SSH do
  @moduledoc """
  Thin wrapper around Erlang's :ssh
  """

  @command_execution_timeout 5 * 60 * 1_000

  require Logger

  @connect_opts [
    port: [
      type: :integer,
      default: 22
    ],
    user: [type: :string, required: true],
    password: [type: :string]
  ]

  @doc """
  Connects to a given host over SSH provided the following options:
  #{NimbleOptions.docs(@connect_opts)}
  """
  def connect(host, opts) when is_list(opts) do
    opts = NimbleOptions.validate!(opts, @connect_opts)

    Logger.debug("Connecting to #{host}")

    :ssh.connect(String.to_charlist(host), opts[:port],
      user: String.to_charlist(opts[:user]),
      password: String.to_charlist(opts[:password]),
      silently_accept_hosts: true
    )
  end

  @doc """
  Disconnects from a server, requires the connection reference.
  """
  def disconnect(connection_ref) do
    Logger.debug("Connection closed.")
    :ssh.close(connection_ref)
  end

  @doc """
  Executes a command over SSH.

  Requires a connection to be already open using `Makina.SSH.connect/2`.
  A session will be automatically created and closed after the command finishes,
  however the SSH connection will still be open and should be closed manually.

  Returns:
  * `{:ok, data}` where data is a map with information about the returned output.
  * `{:error, reason | data}` when either there has been errors launching the command or the executed command returned a non-zero result.
  * `:timeout` in case a timeout has bee reached while waiting for a response.
  """
  def cmd(connection_ref, cmd) do
    Logger.debug("Running command: #{cmd}")

    case :ssh_connection.session_channel(connection_ref, @command_execution_timeout) do
      {:ok, session_id} ->
        :ssh_connection.exec(connection_ref, session_id, cmd, @command_execution_timeout)

        collect_output(connection_ref)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp collect_output(connection_ref, result \\ %{status: nil, data: []}) do
    receive do
      {:ssh_cm, ^connection_ref, {:data, _channel_id, _data_type_code, data}} ->
        collect_output(connection_ref, %{result | data: [data | result[:data]]})

      {:ssh_cm, ^connection_ref, {:eof, _channel_id}} ->
        collect_output(connection_ref, result)

      {:ssh_cm, ^connection_ref, {:exit_status, _channel_id, status}} ->
        Logger.debug("Command exit status: #{status}")
        collect_output(connection_ref, %{result | status: status})

      {:ssh_cm, ^connection_ref, {:closed, _channel_id}} ->
        Logger.debug("Command execution completed, session closed.")

        case result.status do
          0 -> {:ok, %{result | data: prepare_command_output(result[:data])}}
          _ -> {:error, %{result | data: prepare_command_output(result[:data])}}
        end
    after
      @command_execution_timeout ->
        Logger.debug("Timeout waiting for SSH response.")
        :timeout
    end
  end

  defp prepare_command_output(data) do
    data
    |> Enum.reverse()
    |> List.flatten()
    |> Enum.join()
  end
end
