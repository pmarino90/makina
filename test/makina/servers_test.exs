defmodule Makina.ServersTest do
  use ExUnit.Case, async: true

  import Mox

  alias Makina.Infrastructure.RemoteCommand
  alias Makina.Servers
  alias Makina.Models.Server
  alias RemoteCommand

  describe "connect_to_server/1" do
    test "execute a RemoteCommand to connect to the server" do
      server = Server.new(host: "foo.com", user: "bar", password: "password")
      test_pid = self()

      expect(TestRemoteCommandExecutor, :execute, fn
        %RemoteCommand{cmd: :connect_to_server} = command ->
          assert command.server == server

          connected_server = Server.put_private(command.server, :conn_ref, test_pid)

          {:ok, connected_server}
      end)

      Servers.connect_to_server(server)

      verify!()
    end
  end

  describe "create_docker_network/1" do
    test "does not create a network if already exist" do
      expect(TestRemoteCommandExecutor, :execute, fn
        %{cmd: "docker network inspect " <> network_name} ->
          assert network_name == "makina-web-net"

          {:ok, %{}}
      end)

      Servers.create_docker_network(
        Server.new(host: "example.com", user: "foo"),
        "makina-web-net"
      )

      verify!()
    end

    test "creates a network if it doesn't exist " do
      expect(TestRemoteCommandExecutor, :execute, 2, fn
        %{cmd: "docker network inspect " <> network_name} ->
          assert network_name == "makina-web-net"

          {:error, :no_net}

        %{cmd: "docker network create " <> network_name} ->
          assert network_name == "makina-web-net"
          {:ok, %{}}
      end)

      Servers.create_docker_network(
        Server.new(host: "example.com", user: "foo"),
        "makina-web-net"
      )

      verify!()
    end
  end
end
