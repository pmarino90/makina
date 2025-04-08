defmodule Makina.Applications do
  @moduledoc false

  require Logger

  alias Makina.Models.Server
  alias Makina.Models.Application
  alias Makina.SSH
  alias Makina.Docker
  alias Makina.IO

  def deploy_standalone_applications(servers, applications)
      when is_list(servers) and is_list(applications) do
    for server <- servers do
      deploy_applications_on_server(server, applications)
    end
  end

  defp deploy_applications_on_server(%Server{} = server, applications)
       when is_list(applications) do
    Logger.debug("Deploying standalone applications on #{server.host}")

    {:ok, conn_ref} =
      SSH.connect(
        server.host,
        user: server.user,
        password: server.password
      )

    server = Server.put_private(server, :conn_ref, conn_ref)

    results =
      for app <- applications do
        deploy_application_on_server(server, app)
      end

    SSH.disconnect(conn_ref)

    results
  end

  defp deploy_application_on_server(%Server{} = server, %Application{} = app) do
    IO.puts("Deploying \"#{app.name}\"...")

    case Docker.inspect(server, app) |> SSH.execute() do
      {:ok, nil} ->
        Logger.debug("No current instances of #{app.name} running, deploying")

        Docker.run(server, app) |> SSH.execute()

      {:ok, _container} ->
        Logger.debug("A version of #{app.name} is already running, skipping.")
        {:ok, :skipping}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
