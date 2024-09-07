defmodule :"Elixir.Makina.Repo.Migrations.Add-apps-and-containers" do
  use Ecto.Migration

  def change do
    # High level representation of an app
    create table(:applications) do
      add :name, :string, null: false
      add :description, :string

      add :owner_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:applications, [:name], unique: true)

    # an app can be backed by multiple services (db, web, background workers)
    create table(:services) do
      add :name, :string, null: false
      add :image_registry, :string, null: false
      add :image_name, :string, null: false
      add :image_tag, :string, null: false
      add :environment_variables, :map
      add :labels, :map
      add :ports, :map
      add :volumes, :map

      add :application_id, references(:applications, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:services, [:name], unique: true)

    # Runtime reference to a service.
    create table(:instances) do
      add :state, :string, null: false
      add :runtime_id, :string, null: false

      add :service_id, references(:services, on_delete: :delete_all), null: false
      timestamps()
    end
  end
end
