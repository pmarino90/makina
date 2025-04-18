defmodule Makina.Applications do
  @moduledoc false

  require Logger

  alias Makina.Servers
  alias Makina.Models.Server
  alias Makina.Models.Application
  alias Makina.SSH
  alias Makina.Docker
  alias Makina.IO

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

  defp do_stop(%Server{} = server, %Application{} = app) do
    IO.puts(" Stopping \"#{app.name}\"")

    Docker.stop(server, app) |> SSH.execute()
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
        {:ok, :skipping}

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
