defmodule :"Elixir.Makina.Repo.Migrations.Remove-instance-table" do
  use Ecto.Migration

  def change do
    drop table(:instances)
  end
end
