defmodule Makina.Stacks.Service do
  use Ecto.Schema

  import Ecto.Changeset
  import Slugy

  alias Makina.Stacks.{EnvironmentVariable, Volume, Domain}

  @fields ~w[name slug image_registry image_registry_user image_registry_password image_name image_tag expose_service application_id]a
  @required_fields ~w[name slug image_registry image_name image_tag application_id]a

  schema "services" do
    field :name, :string
    field :slug, :string
    field :image_registry, :string, default: "hub.docker.com"
    field :is_private_registry, :boolean, default: false, virtual: true
    field :image_registry_user, :string
    field :image_registry_password, :string, virtual: true, redact: true
    field :image_registry_encrypted_password, :binary, redact: true
    field :image_name, :string
    field :image_tag, :string, default: "latest"
    field :expose_service, :boolean, default: false

    belongs_to :stack, Stack, foreign_key: :application_id

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
    |> maybe_encrypt_registry_password()
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

  def maybe_encrypt_registry_password(changeset) do
    if changed?(changeset, :image_registry_password) do
      clear_password = get_change(changeset, :image_registry_password)

      put_change(
        changeset,
        :image_registry_encrypted_password,
        encrypt_registry_password(clear_password)
      )
    else
      changeset
    end
  end

  def encrypt_registry_password(password) do
    Makina.Vault.encrypt!(password)
  end

  def decrypt_registry_password(password) do
    Makina.Vault.decrypt!(password)
  end
end
