defmodule :"Elixir.Makina.Repo.Migrations.Add-private-registry-option" do
  use Ecto.Migration

  def change do
    alter table(:services) do
      add :image_registry_user, :string
      add :image_registry_unsafe_password, :string
    end
  end
end
