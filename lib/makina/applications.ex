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

    results =
      for app <- applications do
        deploy_application_on_server(conn_ref, app)
      end

    SSH.disconnect(conn_ref)

    Logger.debug("All applications deployed on #{server.host}")
    results
  end

  defp deploy_application_on_server(conn_ref, %Application{} = application) do
    IO.puts("Deploying application application...")
    SSH.exec(conn_ref, Docker.run_command(application))
  end
end
