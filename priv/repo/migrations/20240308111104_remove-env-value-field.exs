defmodule :"Elixir.Makina.Repo.Migrations.Remove-env-value-field" do
  use Ecto.Migration

  def change do
    alter table(:environment_variables) do
      remove :value
    end

    constraint(:environment_variables, :one_value_must_be_set,
      check: "(text_value IS NOT NULL) OR (encrypted_value IS NOT NULL)"
    )
  end
end
