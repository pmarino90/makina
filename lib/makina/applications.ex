defmodule Makina.Applications do
  @moduledoc false

  require Logger

  alias Makina.Servers
  alias Makina.Models.Server
  alias Makina.Models.Application
  alias Makina.SSH
  alias Makina.Docker
  alias Makina.IO

  def deploy_standalone_applications(servers, applications)
      when is_list(servers) and is_list(applications) do
    for server <- servers do
      server = Servers.connect_to_server(server)
      deployment_result = deploy_applications_on_server(server, applications)

      Servers.disconnect_from_server(server)

      deployment_result
    end
  end

  def deploy_applications_on_server(%Server{} = server, applications)
      when is_list(applications) do
    for app <- applications do
      do_deploy_application(server, app)
    end
  end

  defp do_deploy_application(%Server{} = server, %Application{} = app) do
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
