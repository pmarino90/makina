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
