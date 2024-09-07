defmodule :"Elixir.Makina.Repo.Migrations.Change-service-unique-index" do
  use Ecto.Migration

  def change do
    drop index(:services, [:name])
    create index(:services, [:application_id, :name], unique: true)
  end
end
