defmodule Makina.Apps.ApiToken do
  use Ecto.Schema

  alias Makina.Apps.Application
  alias Makina.Apps.ApiToken

  @hash_algorithm :sha256
  @rand_size 32

  schema "api_tokens" do
    field :name, :string
    field :token, :binary

    belongs_to :application, Application

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
end
