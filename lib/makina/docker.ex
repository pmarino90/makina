defmodule Makina.Docker do
  @moduledoc """
  Module that contains all docker-related cli command building functions.
  On their own these do not do anything except returning a correctly formatted
  command that should then be executed over SSH.
  """
  alias Makina.Command
  alias Makina.Models.Server
  alias Makina.Models.Application

  @doc """
  Prepares `docker run` command based on the application being deployed
  """
  def run(%Server{} = server, %Application{} = app) do
    docker(server, "run", [
      "-d",
      "--restart",
      "unless-stopped",
      name(app),
      labels(app),
      volumes(app),
      network(app),
      envs(app),
      ports(app),
      image(app),

      # should always be the last one as it provides additional parameters
      # to the container's running command
      command(app)
    ])
  end

  @doc """
  Prepares the `docker inspect` command for a give container
  """
  def inspect(%Server{} = server, %Application{} = app) do
    docker(server, "inspect", ["--type=container", app_name(app)], fn
      {:ok, result} ->
        info = result[:data] |> String.replace("\n", "") |> JSON.decode!()

        {:ok, info |> List.first()}

      {:error, %{}} ->
        {:ok, nil}

      rest ->
        rest
    end)
  end

  @doc """
  Logs into the private registry defined inside the Application
  """
  def login(%Server{} = server, %Application{} = app) do
    docker(server, "login", [
      app.docker_registry.host,
      "-u",
      app.docker_registry.user,
      "-p",
      app.docker_registry.password
    ])
  end

  @doc """
  Creates a bridged network with the provided name
  """
  def create_network(%Server{} = server, name) do
    docker(server, "network", ["create", name])
  end

  @doc """
    Inspects a network with the provided name
  """
  def inspect_network(%Server{} = server, name) do
    docker(server, "network", ["inspect", name])
  end

  defp app_name(%Application{__scope__: []} = app) do
    app.name
  end

  defp app_name(%Application{} = app) do
    app.__scope__ |> Enum.reverse() |> Enum.join("_")
  end

  defp docker(server, command, args, response_formatter \\ nil) do
    docker_path = Map.get(server.config, :docker_path, "")
    bin = Path.join(docker_path, "docker")
    args = args |> List.flatten() |> Enum.join(" ")
    format_response = response_formatter || fn res -> res end

    %Command{
      cmd: String.trim("#{bin} #{command} " <> args),
      server: server,
      format_response: format_response
    }
  end

  defp image(%Application{} = app) do
    "#{app.docker_image[:name]}:#{app.docker_image[:tag]}"
  end

  defp name(%Application{} = app) do
    ["--name", app_name(app)]
  end

  defp volumes(%Application{} = app) do
    app.volumes
    |> Enum.flat_map(fn v ->
      ["--volume", "#{v.source}:#{v.destination}"]
    end)
  end

  defp network(%Application{domains: []} = app) do
    docker_special_config = app.__docker__

    Map.get(docker_special_config, :networks, [])
    |> Enum.flat_map(fn n ->
      ["--network", n]
    end)
  end

  defp network(%Application{} = app) do
    docker_special_config = app.__docker__

    (Map.get(docker_special_config, :networks, []) ++ ["makina-web-net"])
    |> Enum.flat_map(fn n ->
      ["--network", n]
    end)
  end

  defp labels(%Application{} = app) do
    labels = Map.get(app.__docker__, :labels, []) ++ hash_label(app) ++ proxy_labels(app)

    labels
    |> Enum.flat_map(fn label ->
      ["--label", label]
    end)
  end

  defp envs(%Application{} = app) do
    app.env_vars
    |> Enum.flat_map(fn e ->
      ["--env", "#{e.key}=#{e.value}"]
    end)
  end

  defp ports(%Application{} = app) do
    app.exposed_ports
    |> Enum.flat_map(fn p ->
      ["-p", "#{p.external}:#{p.internal}"]
    end)
  end

  defp command(%Application{} = app) do
    app.__docker__.command
  end

  defp hash_label(%Application{} = app) do
    ["org.makina.app.hash=#{app.__hash__}"]
  end

  defp proxy_labels(%Application{domains: []}) do
    []
  end

  defp proxy_labels(%Application{domains: domains} = app) when is_list(domains) do
    [
      "traefik.enable=true",
      "traefik.http.middlewares.#{app_name(app)}.compress=true",
      "traefik.http.routers.#{app_name(app)}.rule=\"#{format_domains(domains)}\"",
      "traefik.http.routers.#{app_name(app)}.tls.certresolver=letsencrypt",
      "traefik.http.services.#{app_name(app)}.loadBalancer.server.port=#{first_exposed_port(app)}"
    ]
  end

  defp format_domains(domains) when is_list(domains) do
    domains |> Enum.map_join(" || ", fn d -> "Host(\\`#{d}\\`)" end)
  end

  defp first_exposed_port(%Application{exposed_ports: []}) do
    "8080"
  end

  defp first_exposed_port(%Application{} = app) do
    port_pair = app.exposed_ports |> List.first()

    port_pair.external
  end
end
