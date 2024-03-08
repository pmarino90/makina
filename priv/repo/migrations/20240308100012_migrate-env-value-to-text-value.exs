defmodule :"Elixir.Makina.Repo.Migrations.Migrate-env-value-to-text-value" do
  use Ecto.Migration

  alias Ecto.Changeset

  import Ecto.Query

  def up do
    from(v in "environment_variables",
      select: [:id, :value],
      update: [set: [text_value: v.value]]
    )
    |> repo().update_all([])
  end

  def down, do: :ok
end
