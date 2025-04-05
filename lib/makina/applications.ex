defmodule Makina.Applications do
  @moduledoc false

  alias Makina.Definitions.Server
  alias Makina.Definitions.Application
  alias Makina.SSH
  alias Makina.Docker

  def deploy_standalone_applications(servers, applications)
      when is_list(servers) and is_list(applications) do
    for server <- servers do
      deploy_applications_on_server(server, applications)
    end
  end

  defp deploy_applications_on_server(%Server{} = server, applications)
       when is_list(applications) do
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
    results
  end

  defp deploy_application_on_server(conn_ref, %Application{} = application) do
    SSH.exec(conn_ref, Docker.run_command(application))
  end
end
