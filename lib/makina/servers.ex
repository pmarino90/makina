defmodule Makina.Servers do
  @moduledoc false

  use Makina.Infrastructure.RemoteCommand

  require Logger

  alias Makina.Infrastructure.Docker
  alias Makina.Models.Server

  @doc """
  Executes the provided `func` by wrapping it in a remote connection

  A connection to `server` is established before running `func`, the connected server
  is provided as parameter to `func`.
  When `func` returns server is disconnected and the result is returned.

  This function reaises if a connection cannot be established.
  """
  def with_connection!(%Server{} = server, func) when is_function(func, 1) do
    server = connect_to_server(server)
    result = func.(server)
    disconnect_from_server(server)

    result
  end

  def connect_to_server(%Server{} = server) do
    execute_command(%RemoteCommand{cmd: :connect_to_server, server: server})
  end

  def disconnect_from_server(%Server{} = server) do
    execute_command(%RemoteCommand{cmd: :disconnect_from_server, server: server})
  end

  @doc """
  Creates a docker network with a given name
  """
  def create_docker_network(%Server{} = server, name) when is_binary(name) do
    if not network_exists?(server, name) do
      Docker.create_network(server, name) |> execute_command()
    end

    server
  end

  defp network_exists?(server, network) do
    case Docker.inspect_network(server, network) |> execute_command() do
      {:ok, _network} -> true
      {:error, _} -> false
    end
  end
end
