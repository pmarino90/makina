defmodule Makina.SecretProvider.Environment do
  @behaviour Makina.SecretProvider

  def available?() do
    true
  end

  def fetch_secret(var_name) do
    System.get_env(var_name)
  end
end
