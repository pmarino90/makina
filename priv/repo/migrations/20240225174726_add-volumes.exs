defmodule :"Elixir.Makina.Repo.Migrations.Add-volumes" do
  use Ecto.Migration

  def change do
    create table(:volumes) do
      add :name, :string, null: false
      add :mount_point, :string, null: false

      add :service_id, references(:services, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
