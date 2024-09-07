defmodule Makina.Repo.Migrations.RemoveUnsafePassword do
  use Ecto.Migration

  def change do
    alter table(:services) do
      remove :image_registry_unsafe_password
    end
  end
end
