defmodule Makina.Apps.Application do
  use Ecto.Schema

  import Ecto.Changeset

  alias Makina.Apps.Service
  alias Makina.Accounts.User

  schema "applications" do
    field :name, :string
    field :description, :string
    field :state, Ecto.Enum, values: [:stopped, :running, :booting, :new], default: :new

    belongs_to :owner, User
    has_many :services, Service

    timestamps()
  end

  def changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, [:name, :description, :state, :owner_id])
    |> validate_required([:name, :state])
    |> cast_assoc(:services)
  end
end
