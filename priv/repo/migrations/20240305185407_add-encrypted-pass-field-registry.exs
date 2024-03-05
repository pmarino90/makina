defmodule :"Elixir.Makina.Repo.Migrations.Add-encrypted-pass-field-registry" do
  use Ecto.Migration

  def change do
    alter table(:services) do
      add :image_registry_encrypted_password, :binary
    end
  end
end
