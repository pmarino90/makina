defmodule Makina.Stacks.Stack do
  use Ecto.Schema

  import Ecto.Changeset
  import Slugy

  alias Makina.Stacks.{Service, ApiToken}
  alias Makina.Accounts.User

  schema "applications" do
    field :name, :string
    field :slug, :string
    field :description, :string

    belongs_to :owner, User
    has_many :services, Service, foreign_key: :application_id
    has_many :tokens, ApiToken, foreign_key: :application_id

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
