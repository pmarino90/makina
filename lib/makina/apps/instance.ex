defmodule Makina.Apps.Instance do
  alias Makina.Apps.Service
  use Ecto.Schema

  schema "instances" do
    field :state, Ecto.Enum, values: [:running, :stopped]
    field :runtime_id, :string

    belongs_to :service, Service

    timestamps()
  end
end
