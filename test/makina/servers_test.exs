defmodule Makina.ServersTest do
  use ExUnit.Case, async: true

  alias Makina.Infrastructure.RemoteCommand.Executor
  alias Makina.Servers
  alias Makina.Models.Server

  import Mox

  setup_all %{} do
    Mox.defmock(TestRemoteCommandExecutor, for: Executor)
    Application.put_env(:makina, :remote_command_executor, TestRemoteCommandExecutor)
  end

  describe "create_docker_network/1" do
    test "does not create a network if already exist" do
      expect(TestRemoteCommandExecutor, :execute, fn
        %{cmd: "docker network inspect " <> network_name} ->
          assert network_name == "makina-web-net"

          {:ok, %{}}
      end)

      Servers.create_docker_network(Server.new(host: "example.com", user: "foo"))

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

      Servers.create_docker_network(Server.new(host: "example.com", user: "foo"))

      verify!()
    end
  end
end
