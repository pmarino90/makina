defmodule Makina.Servers do
  require Logger

  alias Makina.Applications
  alias Makina.Models.Application
  alias Makina.Models.Server
  alias Makina.SSH
  alias Makina.Docker
  alias Makina.IO

  @docker_web_network "makina-web-net"

  def connect_to_server(%Server{} = server) do
    case SSH.connect(server.host, user: server.user, password: server.password) do
      {:ok, conn_ref} ->
        Server.put_private(server, :conn_ref, conn_ref)

      _err ->
        raise """
        Could not connect to "#{server.host}".
        """
    end
  end

  def disconnect_from_server(%Server{} = server) do
    conn_ref = server.__private__.conn_ref

    SSH.disconnect(conn_ref)
  end

  def prepare_server(%Server{} = server) do
    IO.puts("Prepare server \"#{server.host}\":")

    connect_to_server(server)
    |> puts(" Create network if it doesn't exist")
    |> create_docker_network()
    |> puts(" Done!")
    |> puts(" Deploy support services")
    |> deploy_support_applications()
    |> puts(" Done!")
    |> puts("Server #{server.host} is ready to accept deployments!")
    |> disconnect_from_server()
  end

  def create_docker_network(%Server{} = server) do
    if not network_exists?(server, @docker_web_network) do
      Docker.create_network(server, @docker_web_network) |> SSH.execute()
    end

    server
  end

  defp network_exists?(server, network) do
    case Docker.inspect_network(server, network) |> SSH.execute() do
      {:ok, _network} -> true
      {:error, _} -> false
    end
  end

  defp reverse_proxy() do
    app =
      Application.new(name: "makina-proxy")
      |> Application.set_docker_image(name: "traefik", tag: "v3.3")
      |> Application.put_exposed_port(internal: 80, external: 80)
      |> Application.put_exposed_port(internal: 8080, external: 8080)
      |> Application.put_volume(
        source: "/var/run/docker.sock",
        destination: "/var/run/docker.sock"
      )

    Application.set_private(app, :__docker__, %{
      app.__docker__
      | command: [
          "--entryPoints.web.address=:80",
          "--api.insecure=true",
          "--providers.docker"
        ]
    })
  end

  defp deploy_support_applications(server) do
    system_applications = [
      reverse_proxy()
    ]

    Applications.deploy_applications_on_server(server, system_applications)

    server
  end

  defp puts(server, message) do
    IO.puts(message)
    server
  end
end
