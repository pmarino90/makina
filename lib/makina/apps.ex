defmodule Makina.Apps do
  alias Makina.Repo

  import Ecto.Query

  alias Makina.Apps.{Application, Service}

  @app_preloads [services: [:environment_variables, :volumes, :domains]]

  def list_applications() do
    Application
    |> preload(^@app_preloads)
    |> Repo.all()
  end

  def create_application(attrs) do
    %Application{}
    |> Application.changeset(attrs)
    |> Repo.insert()
  end

  def change_application(attrs \\ %{}) do
    %Application{}
    |> Application.changeset(attrs)
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
  end

  def change_service_environment_variables(service \\ %Service{}, attrs \\ %{}) do
    service
    |> Service.environment_variables_changeset(attrs)
  end

  def update_service_environment_variables(service, attrs) do
    service
    |> change_service_environment_variables(attrs)
    |> Repo.update()
  end

  def change_service_volumes(service \\ %Service{}, attrs \\ %{}) do
    service
    |> Service.volumes_changeset(attrs)
  end

  def update_service_volumes(service, attrs) do
    service
    |> change_service_volumes(attrs)
    |> Repo.update()
  end

  def create_service(attrs) do
    %Service{}
    |> Service.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns a service given its id
  """
  def get_service!(id),
    do: Service |> preload([:domains, :environment_variables, :volumes]) |> Repo.get!(id)

  def get_app!(id), do: Application |> preload(^@app_preloads) |> Repo.get!(id)
end
