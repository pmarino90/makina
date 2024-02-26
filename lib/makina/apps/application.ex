defmodule Makina.Apps.Application do
  use Ecto.Schema

  import Ecto.Changeset
  import Slugy

  alias Makina.Apps.Service
  alias Makina.Accounts.User

  schema "applications" do
    field :name, :string
    field :slug, :string
    field :description, :string

    belongs_to :owner, User
    has_many :services, Service

    timestamps()
  end

  def changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, [:name, :description, :owner_id])
    |> slugify(:name)
    |> validate_required([:name, :slug, :owner_id])
    |> unsafe_validate_unique([:name], Makina.Repo)
    |> cast_assoc(:services)
  end
end
