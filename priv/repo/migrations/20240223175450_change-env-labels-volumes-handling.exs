defmodule :"Elixir.Makina.Repo.Migrations.Change-env-labels-volumes-handling" do
  use Ecto.Migration

  def change do
    alter table(:services) do
      remove :environment_variables
      remove :labels
      remove :volumes
      remove :ports
    end

    create table(:environment_variables) do
      add :name, :string, null: false
      add :value, :string, null: false
      add :type, :string, null: false

      add :service_id, references(:services, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
