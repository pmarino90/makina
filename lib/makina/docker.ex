defmodule Makina.Docker do
  @doc """
  Module that contains all docker-related cli command building functions.
  On their own these do not do anything except returning a correctly formatted
  command that should then be executed over SSH.
  """
  alias Makina.Models.Server
  alias Makina.Models.Application
  alias Makina.SSH

  def run(conn_ref, %Server{} = server, %Application{} = app) do
    cmd =
      docker(server, "run", [
        "-d",
        "--restart",
        "always",
        name(app),
        labels(app),
        volumes(app),
        envs(app),
        image(app),

        # should always be the last one as it provides additional parameters
        # to the container's running command
        command(app)
      ])

    SSH.cmd(conn_ref, cmd)
  end

  def inspect(conn_ref, %Server{} = server, %Application{} = app) do
    cmd = docker(server, "inspect", [app_name(app)])

    case SSH.cmd(conn_ref, cmd) do
      {:ok, result} ->
        info = result[:data] |> String.replace("\n", "") |> JSON.decode!()

        {:ok, info |> List.first()}

      {:error, %{}} ->
        {:ok, nil}

      error ->
        error
    end
  end

  defp app_name(%Application{} = app) do
    app.__scope__ |> Enum.reverse() |> Enum.join("_")
  end

  defp docker(server, command, args) do
    docker_path = Keyword.get(server.config, :docker_path, "")
    bin = Path.join(docker_path, "docker")
    args = args |> List.flatten() |> Enum.join(" ")

    "#{bin} #{command} " <> args
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

  defp labels(%Application{} = app) do
    Map.get(app.__docker__, :labels, [])
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

  defp command(%Application{} = app) do
    app.__docker__.command
  end
end
