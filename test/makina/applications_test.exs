# defmodule Makina.ApplicationsTest do
#   use ExUnit.Case, async: true

#   import Mox

#   alias Makina.Applications
#   alias Makina.Models.Server
#   alias Makina.Models.Application

#   describe "deploy_applications/2" do
#     test "launces commands to deploy a list of applications on all servers" do
#       expect(TestRemoteCommandExecutor, :execute, fn
#         %{cmd: "docker run " <> rest} ->
#           assert rest =~ "test_"

#           dbg(rest)

#           {:ok, %{}}
#       end)

#       servers = [
#         Server.new(host: "example1.com", user: "foo"),
#         Server.new(host: "example1.com", user: "foo")
#       ]

#       apps = [get_dummy_application(), get_dummy_application()]

#       Applications.deploy_applications(servers, apps)

#       verify!()
#     end
#   end

#   defp get_dummy_application() do
#     Application.new(name: "test_#{DateTime.utc_now()}")
#     |> Application.set_docker_image(name: "foo")
#   end
# end
