defmodule Makina.Docker do
  @doc """
  Module that contains all docker-related cli command building functions.
  On their own these do not do anything except returning a correctly formatted
  command that should then be executed over SSH.
  """
  alias Makina.Models.Server
  alias Makina.Models.Application
  alias Makina.SSH

  def run_command(conn_ref, %Server{} = server, %Application{} = app) do
    cmd =
      docker(server, "run", [
        "-d",
        "--restart",
        "always",
        "--name",
        "#{app_name(app)}",
        "--label",
        "org.makina.app.hash=#{app.hash}",
        app.docker_image[:name],
        "--tag",
        app.docker_image[:tag]
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
    app.scope |> Enum.reverse() |> Enum.join("_")
  end

  defp docker(server, command, args) do
    docker_path = Keyword.get(server.config, :docker_path, "")
    bin = Path.join(docker_path, "docker")
    args = Enum.join(args, " ")

    "#{bin} #{command} " <> args
  end
end
