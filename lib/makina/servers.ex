defmodule Makina.Servers do
  require Logger

  alias Makina.Infrastructure.RemoteCommand
  alias Makina.Applications
  alias Makina.Models.Application
  alias Makina.Models.Server
  alias Makina.Models.ProxyConfig
  alias Makina.Models.Context
  alias Makina.Infrastructure.SSH
  alias Makina.Infrastructure.Docker
  alias Makina.Infrastructure.IO

  @docker_web_network "makina-web-net"

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

  def prepare_server(%Server{} = server, %Context{} = ctx) do
    IO.puts("Prepare server \"#{server.host}\":")

    connect_to_server(server)
    |> puts(" Create network if it doesn't exist")
    |> create_docker_network()
    |> puts(" Done!")
    |> puts(" Deploy support services")
    |> deploy_support_applications(ctx)
    |> puts(" Done!")
    |> puts("Server #{server.host} is ready to accept deployments!")
    |> disconnect_from_server()
  end

  def create_docker_network(%Server{} = server) do
    if not network_exists?(server, @docker_web_network) do
      Docker.create_network(server, @docker_web_network) |> execute_command()
    end

    server
  end

  defp network_exists?(server, network) do
    case Docker.inspect_network(server, network) |> execute_command() do
      {:ok, _network} -> true
      {:error, _} -> false
    end
  end

  defp reverse_proxy(proxy_config) do
    app =
      Application.new(name: "makina-proxy")
      |> Application.set_docker_image(name: "traefik", tag: "v3.3")
      |> Application.put_exposed_port(internal: 80, external: 80)
      |> expose_https_ports(proxy_config)
      |> Application.put_volume(
        source: "/var/run/docker.sock",
        destination: "/var/run/docker.sock"
      )
      |> Application.put_volume(
        source: "makina-proxy",
        destination: "/var/proxy/data/"
      )

    base_command = [
      "--entryPoints.web.address=:80",
      "--providers.docker",
      "--providers.docker.exposedByDefault=false",
      "--providers.docker.network=#{@docker_web_network}"
    ]

    Application.set_private(app, :__docker__, %{
      app.__docker__
      | networks: [@docker_web_network],
        command:
          base_command
          |> put_https_command_args(proxy_config)
    })
  end

  defp expose_https_ports(app, nil) do
    app
  end

  defp expose_https_ports(app, %ProxyConfig{https_enabled: https}) when not is_nil(https) do
    Application.put_exposed_port(app, internal: 443, external: 443)
  end

  defp put_https_command_args(command, nil) do
    command
  end

  defp put_https_command_args(
         command,
         %ProxyConfig{https_enabled: config}
       ) do
    letsencrypt_config = config[:letsencrypt]

    command ++
      [
        "--entryPoints.websecure.address=:443",
        "--entryPoints.web.http.redirections.entryPoint.to=websecure",
        "--entryPoints.web.http.redirections.entryPoint.permanent=true",
        "--entryPoints.web.http.redirections.entryPoint.scheme=https",
        "--certificatesResolvers.letsencrypt.acme.email=#{letsencrypt_config[:email]}",
        "--certificatesResolvers.letsencrypt.acme.storage=/var/proxy/data/letsencrypt/acme.json",
        "--certificatesResolvers.letsencrypt.acme.keyType=EC384",
        "--certificatesResolvers.letsencrypt.acme.httpChallenge.entryPoint=web"
      ]
  end

  defp deploy_support_applications(server, ctx) do
    system_applications = [
      reverse_proxy(ctx.proxy_config)
    ]

    Applications.deploy_standalone_applications([server], system_applications)

    server
  end

  defp puts(server, message) do
    IO.puts(message)
    server
  end

  defp execute_command(%RemoteCommand{} = command) do
    mod = Elixir.Application.get_env(:makina, :remote_command_executor, SSH)

    mod.execute(command)
  end
end
