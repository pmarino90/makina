defmodule Makina.Stacks.ApiToken do
  use Ecto.Schema

  alias Makina.Repo
  alias Makina.Stacks.Stack
  alias Makina.Stacks.ApiToken

  import Ecto.Query

  @hash_algorithm :sha256
  @rand_size 32

  schema "api_tokens" do
    field :name, :string
    field :token, :binary

    belongs_to :stack, Stack, foreign_key: :application_id

    timestamps(updated_at: false)
  end

  def build_api_token(name, application) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %ApiToken{
       token: hashed_token,
       name: name,
       application_id: application.id
     }}
  end

  def verify_token_for_app(id, auth_token) do
    case Base.url_decode64(auth_token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query = from t in ApiToken, where: t.token == ^hashed_token and t.application_id == ^id

        Repo.exists?(query)

      :error ->
        false
    end
  end
end
