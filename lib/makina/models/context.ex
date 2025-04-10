defmodule Makina.Models.Context do
  @moduledoc """
  Represents the context of a Makinafile
  """

  alias Makina.Models.Context
  alias Makina.Models.ProxyConfig

  defstruct id: nil, servers: [], standalone_applications: [], proxy_config: nil

  @type t() :: %Context{
          id: nonempty_binary(),
          servers: list(),
          standalone_applications: list(),
          proxy_config: ProxyConfig.t()
        }

  @spec new(opts :: keyword()) :: Context.t()
  def new(opts) do
    opts = Keyword.put(opts, :proxy_config, prepare_proxy_config(opts[:proxy_config]))

    struct(__MODULE__, opts)
  end

  defp prepare_proxy_config(opts), do: ProxyConfig.new(opts)
end
