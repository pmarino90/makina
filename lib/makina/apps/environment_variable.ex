defmodule Makina.Apps.EnvironmentVariable do
  use Ecto.Schema

  import Ecto.Changeset

  alias Makina.Apps.Service

  schema "environment_variables" do
    field :name, :string
    field :value, :string
    field :type, Ecto.Enum, values: [:plain], default: :plain

    belongs_to :service, Service

    timestamps()
  end

  def changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, [:name, :value, :type, :service_id])
    |> validate_required([:name, :value, :type])
  end
end
