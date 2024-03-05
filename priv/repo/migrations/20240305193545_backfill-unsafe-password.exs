defmodule :"Elixir.Makina.Repo.Migrations.Backfill-unsafe-password.Service" do
  use Ecto.Schema

  schema "services" do
    field(:name, :string)
    field(:slug, :string)
    field(:image_registry, :string, default: "hub.docker.com")
    field(:is_private_registry, :boolean, default: false, virtual: true)
    field(:image_registry_user, :string)
    field(:image_registry_unsafe_password, :string)
    field(:image_registry_password, :string, virtual: true, redact: true)
    field(:image_registry_encrypted_password, :binary, redact: true)
    field(:image_name, :string)
    field(:image_tag, :string, default: "latest")
    field(:expose_service, :boolean, default: false)

    timestamps()
  end
end

defmodule :"Elixir.Makina.Repo.Migrations.Backfill-unsafe-password" do
  use Ecto.Migration
  alias :"Elixir.Makina.Repo.Migrations.Backfill-unsafe-password.Service", as: Service

  import Ecto.Query

  def up do
    unsafe_passwords =
      repo().all(from(s in Service, where: not is_nil(s.image_registry_unsafe_password)))

    for service <- unsafe_passwords do
      service
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_change(
        :image_registry_encrypted_password,
        Makina.Vault.encrypt!(service.image_registry_unsafe_password)
      )
      |> repo().update()
    end
  end

  def down, do: :ok
end
