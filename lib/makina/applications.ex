defmodule Makina.Applications do
  @moduledoc false

  require Logger

  alias Makina.Infrastructure.RemoteCommand
  alias Makina.Infrastructure.SSH
  alias Makina.Infrastructure.Docker
  alias Makina.Infrastructure.IO

  alias Makina.Servers
  alias Makina.Models.Server
  alias Makina.Models.Application

  @doc """
  Deploys a list of application on a server or a list of servers

  If a list of servers is provided the function iterates the list and
  connects to the server before deploying the application.
  Connection is established before triggering applications deployment
  and disconnection happens when all applications have been deployed.
  """
  def deploy_applications(servers, applications)
      when is_list(servers) and is_list(applications) do
    for server <- servers do
      server = Servers.connect_to_server(server)
      deployment_result = deploy_applications(server, applications)

      Servers.disconnect_from_server(server)

      deployment_result
    end
  end

  def deploy_applications(%Server{} = server, applications)
      when is_list(applications) do
    for app <- applications do
      deploy_application(server, app)
    end
  end

  @doc """
  Stops all provided applications in all servers

  If `servers` is a list then the function iterates on them and attempt to connect
  to the server.
  Servers and applications are processed sequentially.
  """
  def stop_applications(servers, applications) when is_list(servers) and is_list(applications) do
    for server <- servers do
      server = Servers.connect_to_server(server)
      deployment_result = stop_applications(server, applications)

      Servers.disconnect_from_server(server)

      deployment_result
    end
  end

  def stop_applications(%Server{} = server, applications) when is_list(applications) do
    for app <- applications do
      stop_application(server, app)
    end
  end

  @doc """
  Deploys an application on a specific server

  Note: The server has to have a connection at this point.
  """
  def deploy_application(%Server{} = server, %Application{} = app) do
    if Server.connected?(server) do
      do_deploy(server, app)
    else
      connect_and_deploy(server, app)
    end
  end

  @doc """
  Stops an application on a given server
  """
  def stop_application(%Server{} = server, %Application{} = app) do
    if Server.connected?(server) do
      do_stop(server, app)
    else
      connect_and_stop(server, app)
    end
  end

  def update_application(%Server{} = server, %Application{} = app) do
    if Server.connected?(server) do
      do_update(server, app)
    else
      connect_and_update(server, app)
    end
  end

  def remove_application(%Server{} = server, %Application{} = app) do
    Docker.remove(server, app) |> execute_command()
  end

  def remove_application_by_name(%Server{} = server, name) when is_binary(name) do
    Docker.remove(server, name) |> execute_command()
  end

  def inspect_deployed_application(%Server{} = server, %Application{} = app) do
    Docker.inspect(server, app) |> execute_command()
  end

  defp execute_command(%RemoteCommand{} = cmd) do
    SSH.execute(cmd)
  end

  defp do_update(%Server{} = server, %Application{} = app) do
    IO.puts(" Updating \"#{app.name}\"")

    with {:ok, :update} <- check_update_required(server, app),
         {:ok, _} <- remove_stale_app(server, app),
         {:ok, _} <- mark_app_as_stale(server, app),
         {:ok, _} <- do_deploy(server, app),
         {:ok, _} <- stop_stale_app(server, app) do
      {:ok, :updated}
    else
      {:ok, :no_update} ->
        IO.puts(" No update needed for \"#{app.name}\"")
        {:ok, :no_update}

      error ->
        error
    end
  end

  defp check_update_required(server, app) do
    case inspect_deployed_application(server, app) do
      {:ok, container} ->
        running_hash = get_in(container, ["Config", "Labels", "org.makina.app.hash"])

        cond do
          is_nil(running_hash) -> {:error, :no_app}
          String.to_integer(running_hash) != app.__hash__ -> {:ok, :update}
          String.to_integer(running_hash) == app.__hash__ -> {:ok, :no_update}
        end

      {:error, _} ->
        {:error, :no_app}
    end
  end

  defp connect_and_update(%Server{} = server, %Application{} = app) do
    server = Servers.connect_to_server(server)
    result = do_update(server, app)
    Servers.disconnect_from_server(server)

    result
  end

  defp do_stop(%Server{} = server, %Application{} = app) do
    IO.puts(" Stopping \"#{app.name}\"")

    Docker.stop(server, app) |> SSH.execute()
  end

  defp mark_app_as_stale(%Server{} = server, %Application{} = app) do
    Docker.rename_container(server, app, suffix: "__stale") |> SSH.execute()
  end

  defp stop_stale_app(%Server{} = server, %Application{} = app) do
    Docker.stop(server, "#{Docker.app_name(app)}__stale") |> SSH.execute()
  end

  defp remove_stale_app(%Server{} = server, %Application{} = app) do
    stale_name = "#{Docker.app_name(app)}__stale"

    case Docker.inspect(server, stale_name) |> execute_command() do
      {:ok, _} ->
        remove_application_by_name(server, stale_name)

      {:error, _} ->
        {:ok, :no_app}
    end
  end

  defp connect_and_stop(%Server{} = server, %Application{} = app) do
    server = Servers.connect_to_server(server)
    result = do_stop(server, app)
    Servers.disconnect_from_server(server)

    result
  end

  defp connect_and_deploy(%Server{} = server, %Application{} = app) do
    server = Servers.connect_to_server(server)
    result = do_deploy(server, app)
    Servers.disconnect_from_server(server)

    result
  end

  def do_deploy(%Server{} = server, %Application{} = app) do
    IO.puts(" Deploying \"#{app.name}\"")

    with {:ok, _} <- maybe_login_to_registry(server, app),
         {:ok, nil} <- ensure_app_not_running(server, app) do
      Logger.debug("No current instances of #{app.name} running, deploying")

      Docker.run(server, app) |> SSH.execute()
    else
      {:ok, _container} ->
        Logger.debug("A version of #{app.name} is already running, skipping.")
        do_update(server, app)

      {:error, reason} ->
        {:error, reason}

      err ->
        err
    end
  end

  defp ensure_app_not_running(server, app) do
    Docker.inspect(server, app) |> SSH.execute()
  end

  defp maybe_login_to_registry(server, app) do
    if Application.private_docker_registry?(app) do
      Docker.login(server, app) |> SSH.execute()
    else
      {:ok, :no_login}
    end
  end
end
