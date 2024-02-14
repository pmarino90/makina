defmodule Makina.Repo do
  use Ecto.Repo,
    otp_app: :makina,
    adapter: Ecto.Adapters.SQLite3
end
