defmodule :"Elixir.Makina.Repo.Migrations.Add-command-field-in-service" do
  use Ecto.Migration

  def change do
    alter table(:services) do
      add :command, {:array, :string}, nil: true
    end
  end
end
