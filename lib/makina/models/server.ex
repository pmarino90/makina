defmodule Makina.Models.Server do
  alias Makina.Models.Internal

  @derive {JSON.Encoder, except: [:password]}
  defstruct hash: nil, host: "", port: 22, user: "", password: nil

  def new(opts) do
    server = struct(__MODULE__, opts)
    Map.put(server, :hash, Internal.hash(server))
  end
end
