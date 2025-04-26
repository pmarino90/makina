defmodule Makina.ServerInitializer do
  @moduledoc false

  alias Makina.Models.Context
  alias Makina.Models.Server
  alias Makina.Models.Application
  alias Makina.Models.ProxyConfig
  alias Makina.Servers
  alias Makina.Applications
  alias Makina.Infrastructure.IO

  @docker_web_network "makina-web-net"

  def initialize_from_context(%Server{} = server, %Context{} = ctx) do
    IO.puts("Prepare server \"#{server.host}\":")

    Servers.with_connection!(server, fn s ->
      s
      |> puts(" Create network if it doesn't exist")
      |> Servers.create_docker_network(@docker_web_network)
      |> puts(" Done!")
      |> puts(" Deploy support services")
      |> deploy_support_applications(ctx)
      |> puts(" Done!")
      |> puts("Server #{server.host} is ready to accept deployments!")
    end)
  end

  defp deploy_support_applications(server, ctx) do
    system_applications = [
      reverse_proxy(ctx.proxy_config)
    ]

    Applications.deploy_applications([server], system_applications)

    server
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

  defp puts(server, message) do
    IO.puts(message)
    server
  end
end
