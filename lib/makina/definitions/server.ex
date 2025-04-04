defmodule Makina.Definitions.Server do
  @derive {JSON.Encoder, except: [:password]}
  defstruct host: "", port: 22, user: "", password: nil
end
