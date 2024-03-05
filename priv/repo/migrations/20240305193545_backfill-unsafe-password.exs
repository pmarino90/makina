defmodule :"Elixir.Makina.Repo.Migrations.Backfill-unsafe-password" do
  use Ecto.Migration
  alias Makina.Apps.Service

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
