defmodule Makina.Apps.Volume do
  use Ecto.Schema

  import Ecto.Changeset

  alias Makina.Apps.Service

  schema "volumes" do
    field :name, :string
    field :mount_point, :string

    belongs_to :service, Service

    timestamps()
  end

  def changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:name, :mount_point, :service_id])
    |> validate_required([:name, :mount_point])
  end
end
