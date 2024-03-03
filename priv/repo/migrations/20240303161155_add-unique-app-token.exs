defmodule :"Elixir.Makina.Repo.Migrations.Add-unique-app-token" do
  use Ecto.Migration

  def change do
    create index(:api_tokens, [:application_id, :token], unique: true)
  end
end
