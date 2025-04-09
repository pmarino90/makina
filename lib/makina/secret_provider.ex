defmodule Makina.SecretProvider do
  @moduledoc """
  Simple secret provider

  Offers an interface different providers should implement in order to fetch
  secrets within a Makinafile.
  """

  @callback available?() :: boolean()
  @callback fetch_secret(options :: term()) :: String.t()

  @providers %{
    environment: Makina.SecretProvider.Environment,
    one_password: Makina.SecretProvider.OnePassword
  }

  @doc """
  Checks whether the selected secret provider is available on the current host
  """
  def available?(provider) when is_map_key(@providers, provider) do
    @providers[provider].available?()
  end

  def available?(_provider), do: false

  @doc """
  Fetches a secret from a provider given a set of options
  """
  def fetch_secret(provider, options) when is_map_key(@providers, provider) do
    @providers[provider].fetch_secret(options)
  end
end
