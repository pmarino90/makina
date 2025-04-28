defmodule Makina.ApplicationsTest do
  use ExUnit.Case, async: true

  import Mox

  alias Makina.Infrastructure.RemoteCommand
  alias Makina.Applications
  alias Makina.Models.Server
  alias Makina.Models.Application

  describe "deploy_applications/2" do
    test "deploys applications from scratch" do
      server = Server.new(host: "example1.com", user: "foo")
      test_pid = self()
      apps = [get_dummy_application()]

      servers = [
        server
      ]

      expect(TestRemoteCommandExecutor, :execute, 4, fn
        %RemoteCommand{cmd: :connect_to_server} = command ->
          assert command.server == server

          Server.put_private(command.server, :conn_ref, test_pid)

        %RemoteCommand{cmd: :disconnect_from_server} = command ->
          assert command.server == %Server{server | __private__: %{conn_ref: test_pid}}

          :ok

        %RemoteCommand{cmd: "docker inspect " <> rest} ->
          assert rest =~ "test_"

          {:ok, nil}

        %RemoteCommand{cmd: "docker run " <> rest} ->
          assert rest =~ "test_"

          {:ok, %{}}
      end)

      Applications.deploy_applications(servers, apps)

      verify!()
    end

    test "deploying same application wont affect running one" do
      server = Server.new(host: "example1.com", user: "foo")
      test_pid = self()
      apps = [get_dummy_application()]

      servers = [
        server
      ]

      expect(TestRemoteCommandExecutor, :execute, 4, fn
        %RemoteCommand{cmd: :connect_to_server} = command ->
          assert command.server == server

          Server.put_private(command.server, :conn_ref, test_pid)

        %RemoteCommand{cmd: :disconnect_from_server} = command ->
          assert command.server == %Server{server | __private__: %{conn_ref: test_pid}}

          :ok

        %RemoteCommand{cmd: "docker inspect " <> rest} ->
          assert rest =~ "test_"
          app = Enum.find(apps, fn a -> rest =~ a.name end)

          response = %{
            "Config" => %{
              "Labels" => %{"org.makina.app.hash" => "#{app.__hash__}"}
            }
          }

          {:ok, response}
      end)

      Applications.deploy_applications(servers, apps)

      verify!()
    end
  end

  defp get_dummy_application() do
    Application.new(name: "test_#{:rand.uniform()}")
    |> Application.set_docker_image(name: "foo")
  end
end
