defmodule Makina.Apps.Service do
  use Ecto.Schema

  import Ecto.Changeset

  alias Makina.Apps.{Application, EnvironmentVariable, Volume}

  @fields ~w[name image_name image_tag application_id]a
  @required_fields ~w[name image_registry image_name image_tag application_id]a

  schema "services" do
    field :name, :string
    field :image_registry, :string, default: "hub.docker.com"
    field :image_name, :string
    field :image_tag, :string, default: "latest"

    belongs_to :application, Application

    has_many :environment_variables, EnvironmentVariable, on_replace: :delete
    has_many :volumes, Volume, on_replace: :delete

    timestamps()
  end

  def changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, @fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:environment_variables,
      with: &EnvironmentVariable.changeset/2,
      sort_param: :envs_sort,
      drop_param: :envs_drop
    )
    |> cast_assoc(:volumes,
      with: &Volume.changeset/2,
      sort_param: :volumes_sort,
      drop_param: :volumes_drop
    )
  end
end
