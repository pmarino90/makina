defmodule Makina.Apps.Application do
  use Ecto.Schema

  import Ecto.Changeset

  alias Makina.Apps.Service
  alias Makina.Accounts.User

  schema "applications" do
    field :name, :string
    field :description, :string

    belongs_to :owner, User
    has_many :services, Service

    timestamps()
  end

  def changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, [:name, :description, :owner_id])
    |> validate_required([:name])
    |> cast_assoc(:services)
  end
end
