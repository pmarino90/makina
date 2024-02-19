defmodule Makina.Apps.Service do
  use Ecto.Schema

  import Ecto.Changeset

  alias Makina.Apps.{Application, Instance}

  @fields ~w[name image_name image_tag environment_variables labels ports volumes]a
  @required_fields ~w[name image_registry image_name image_tag]a

  schema "services" do
    field :name, :string
    field :image_registry, :string, default: "hub.docker.com"
    field :image_name, :string
    field :image_tag, :string, default: "latest"
    field :environment_variables, :map
    field :labels, :map
    field :ports, :map
    field :volumes, :map

    belongs_to :application, Application
    has_many :instances, Instance

    timestamps()
  end

  def changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
  end
end
