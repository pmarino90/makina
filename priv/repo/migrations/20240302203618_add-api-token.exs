defmodule :"Elixir.Makina.Repo.Migrations.Add-api-token" do
  use Ecto.Migration

  def change do
    create table(:api_tokens) do
      add :name, :string, null: false
      add :token, :binary, null: false, size: 32

      add :application_id, references(:applications, on_delete: :delete_all)

      timestamps(updated_at: false)
    end
  end
end
