defmodule Makina.Apps.EnvironmentVariable do
  use Ecto.Schema

  import Ecto.Changeset

  alias Makina.Apps.Service

  schema "environment_variables" do
    field :name, :string
    field :value, :string, redact: true, virtual: true
    field :text_value, :string
    field :encrypted_value, :binary, redact: true
    field :type, Ecto.Enum, values: [:plain, :secret], default: :plain

    belongs_to :service, Service

    timestamps()
  end

  def changeset(changeset, attrs \\ %{}) do
    changeset
    |> cast(attrs, [:name, :value, :type, :service_id])
    |> validate_required([:name, :value, :type])
    |> maybe_encrypt_value()
  end

  defp maybe_encrypt_value(changeset) do
    if get_change(changeset, :type) == :secret and get_change(changeset, :value) != nil do
      changeset
      |> put_change(:encrypted_value, Makina.Vault.encrypt!(get_change(changeset, :value)))
    else
      changeset
      |> put_change(:text_value, get_change(changeset, :value))
    end
  end
end
