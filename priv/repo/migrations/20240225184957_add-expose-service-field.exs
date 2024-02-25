defmodule :"Elixir.Makina.Repo.Migrations.Add-expose-service-field" do
  use Ecto.Migration

  def change do
    alter table(:services) do
      add :expose_service, :boolean, null: false, default: false
    end

    create table(:domains) do
      add :domain, :string, null: false

      add :service_id, references(:services, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
