defmodule Makina.Apps.Service do
  use Ecto.Schema

  import Ecto.Changeset
  import Slugy

  alias Makina.Apps.{Application, EnvironmentVariable, Volume, Domain}

  @fields ~w[name slug image_registry image_registry_user image_registry_unsafe_password image_name image_tag expose_service application_id]a
  @required_fields ~w[name slug image_registry image_name image_tag application_id]a

  schema "services" do
    field :name, :string
    field :slug, :string
    field :image_registry, :string, default: "hub.docker.com"
    field :is_private_registry, :boolean, default: false, virtual: true
    field :image_registry_user, :string
    field :image_registry_unsafe_password, :string
    field :image_name, :string
    field :image_tag, :string, default: "latest"
    field :expose_service, :boolean, default: false

    belongs_to :application, Application

    has_many :environment_variables, EnvironmentVariable, on_replace: :delete
    has_many :volumes, Volume, on_replace: :delete
    has_many :domains, Domain, on_replace: :delete

    timestamps()
  end

  def domains_changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, [])
    |> cast_assoc(:domains,
      with: &Domain.changeset/2,
      sort_param: :domains_sort,
      drop_param: :domains_drop
    )
  end

  def environment_variables_changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, [])
    |> cast_assoc(:environment_variables,
      with: &EnvironmentVariable.changeset/2,
      sort_param: :envs_sort,
      drop_param: :envs_drop
    )
  end

  def volumes_changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, [])
    |> cast_assoc(:volumes,
      with: &Volume.changeset/2,
      sort_param: :volumes_sort,
      drop_param: :volumes_drop
    )
  end

  def changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, @fields)
    |> slugify(:name)
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
    |> cast_assoc(:domains,
      with: &Domain.changeset/2,
      sort_param: :domains_sort,
      drop_param: :domains_drop
    )
  end
end
