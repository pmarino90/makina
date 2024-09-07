defmodule Makina.Stacks do
  alias Makina.Runtime
  alias Phoenix.PubSub
  alias Makina.Repo

  import Ecto.Query

  alias Makina.Stacks.{Stack, Service, ApiToken}

  @service_preloads [:environment_variables, :volumes, :domains]
  @app_preloads [:tokens, services: @service_preloads]

  def list_applications() do
    Stack
    |> preload(^@app_preloads)
    |> Repo.all()
  end

  def create_application(attrs) do
    %Stack{}
    |> Stack.changeset(attrs)
    |> Repo.insert()
    |> preload_app()
    |> start_app()
  end

  def change_application(attrs \\ %{}) do
    %Stack{}
    |> Stack.changeset(attrs)
  end

  def delete_application(app) do
    Repo.delete(app)
    |> stop_app()
  end

  def delete_service(service) do
    Repo.delete(service)
    |> stop_service()
  end

  def change_service(attrs \\ %{}) do
    %Service{}
    |> Service.changeset(attrs)
  end

  def change_service_domains(service \\ %Service{}, attrs \\ %{}) do
    service
    |> Service.domains_changeset(attrs)
  end

  def update_service_domains(service, attrs) do
    service
    |> change_service_domains(attrs)
    |> Repo.update()
    |> notify_config_change(:domains)
  end

  def change_service_environment_variables(service \\ %Service{}, attrs \\ %{}) do
    service
    |> Service.environment_variables_changeset(attrs)
  end

  def update_service_environment_variables(service, attrs) do
    service
    |> change_service_environment_variables(attrs)
    |> Repo.update()
    |> notify_config_change(:environment_variables)
  end

  def change_service_volumes(service \\ %Service{}, attrs \\ %{}) do
    service
    |> Service.volumes_changeset(attrs)
  end

  def update_service_volumes(service, attrs) do
    service
    |> change_service_volumes(attrs)
    |> Repo.update()
    |> notify_config_change(:volumes)
  end

  def create_service(attrs) do
    %Service{}
    |> Service.changeset(attrs)
    |> Repo.insert()
    |> preload_service()
    |> start_service()
  end

  def create_api_token(name, application) do
    {token, struct} = ApiToken.build_api_token(name, application)

    Repo.insert(struct)

    token
  end

  def verify_token_for_app(app_id, auth_token) do
    ApiToken.verify_token_for_app(app_id, auth_token)
  end

  @doc """
  Returns a service given its id
  """
  def get_service!(id),
    do:
      Service
      |> preload([:domains, :environment_variables, :volumes])
      |> Repo.get!(id)
      |> put_env_value()

  def get_app!(id), do: Stack |> preload(^@app_preloads) |> Repo.get!(id)

  def trigger_service_redeploy(service) do
    PubSub.broadcast(
      Makina.PubSub,
      "system::service::#{service.id}",
      {:redeploy, []}
    )
  end

  defp notify_config_change({:ok, service} = res, section) do
    PubSub.broadcast(
      Makina.PubSub,
      "system::service::#{service.id}",
      {:config_update, section, service}
    )

    res
  end

  defp notify_config_change({:error, _} = res, _), do: res

  defp preload_app({:ok, %Stack{} = app}) do
    {:ok, Repo.preload(app, @app_preloads)}
  end

  defp preload_app({:error, _} = res) do
    res
  end

  defp preload_service({:ok, %Service{} = service}) do
    {:ok, Repo.preload(service, @service_preloads)}
  end

  defp preload_service({:error, _} = res) do
    res
  end

  defp start_app({:ok, %Stack{} = app} = res) do
    Runtime.start_app(app)

    res
  end

  defp start_app({:error, _} = res), do: res

  defp start_service({:ok, %Service{} = service} = res) do
    Runtime.start_service(service.stack, service)

    res
  end

  defp start_service({:error, _} = res), do: res

  defp stop_app({:ok, %Stack{} = app} = res) do
    Runtime.stop_app(app.id)

    res
  end

  defp stop_app({:error, _} = res), do: res

  defp stop_service({:ok, %Service{} = service} = res) do
    Runtime.stop_service(service)

    res
  end

  defp stop_service({:error, _} = res), do: res

  defp put_env_value(service) do
    vars =
      service.environment_variables
      |> Enum.map(fn var ->
        case var.type do
          :plain -> Map.put(var, :value, var.text_value)
          :secret -> Map.put(var, :value, "*****")
        end
      end)

    Map.put(service, :environment_variables, vars)
  end
end
