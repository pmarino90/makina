defmodule :"Elixir.Makina.Repo.Migrations.Add-volume-from-local-path" do
  use Ecto.Migration

  def change do
    alter table(:volumes) do
      add :local_path, :string
    end
  end
end
