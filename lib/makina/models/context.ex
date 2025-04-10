defmodule Makina.Models.Context do
  @moduledoc """
  Represents the context of a Makinafile
  """

  alias Makina.Models.Context
  alias Makina.Models.ProxyConfig

  @derive JSON.Encoder
  defstruct id: nil, servers: [], standalone_applications: [], proxy_config: nil

  @type t() :: %Context{
          id: nonempty_binary(),
          servers: list(),
          standalone_applications: list(),
          proxy_config: ProxyConfig.t()
        }

  @spec new(opts :: keyword()) :: Context.t()
  def new(opts) do
    struct(__MODULE__, opts)
  end
end
