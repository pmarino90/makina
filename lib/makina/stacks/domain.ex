defmodule Makina.Stacks.Domain do
  alias Makina.Stacks.Service
  use Ecto.Schema

  import Ecto.Changeset

  schema "domains" do
    field :domain, :string

    belongs_to :service, Service

    timestamps()
  end

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:domain, :service_id])
    |> validate_required([:domain])
  end
end
