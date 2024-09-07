defmodule :"Elixir.Makina.Repo.Migrations.Add-encrypted-env-var-value" do
  use Ecto.Migration

  def change do
    alter table(:environment_variables) do
      add :encrypted_value, :binary
      add :text_value, :string
    end

    constraint(:environment_variables, :one_value_must_be_set,
      check: "(text_value IS NOT NULL) OR (encrypted_value IS NOT NULL)"
    )
  end
end
