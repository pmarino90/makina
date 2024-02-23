defmodule Makina.Apps do
  alias Makina.Repo

  import Ecto.Query

  alias Makina.Apps.Service
  alias Makina.Apps.Application

  def list_applications(), do: Application |> preload(:services) |> Repo.all()

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

  @doc """
  Returns a service given its id
  """
  def get_service!(id), do: Service |> Repo.get!(id)

  def get_app!(id), do: Application |> preload(:services) |> Repo.get!(id)
end
