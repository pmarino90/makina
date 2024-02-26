defmodule :"Elixir.Makina.Repo.Migrations.Add-slugs" do
  use Ecto.Migration

  def change do
    alter table(:applications) do
      add :slug, :string
    end

    alter table(:services) do
      add :slug, :string
    end
  end
end
