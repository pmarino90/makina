defmodule Makina.Models.ProxyConfig do
  alias Makina.Models.ProxyConfig

  @derive JSON.Encoder
  defstruct https_enabled: nil

  @type t() :: %ProxyConfig{https_enabled: nil | acme_config()}

  @typedoc """
  Defines the type of the configuration used to setup LetsEcrypt ACME challange
  """
  @type acme_config() :: {:letsencrypt, %{email: String.t()}}

  @spec new(opts :: keyword()) :: ProxyConfig.t()
  def new(nil) do
    %ProxyConfig{https_enabled: nil}
  end

  def new(opts) do
    struct(ProxyConfig, opts)
  end
end
