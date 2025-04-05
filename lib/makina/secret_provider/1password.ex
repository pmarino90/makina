defmodule Makina.SecretProvider.OnePassword do
  @moduledoc false
  @behaviour Makina.SecretProvider

  def available?() do
    case System.shell("command -v op") do
      {_, 0} -> true
      _ -> false
    end
  end

  def fetch_secret(options) do
    case exec(options) do
      {secret, 0} ->
        secret |> String.trim()

      {error, _} ->
        raise """
        Couldn't fetch the sercret from 1Password.
        Please check it is correctly setup on your system and that the configuration
        provided is correct.

        #{error}
        """
    end
  end

  defp exec(options) do
    System.cmd("op", [
      "item",
      "get",
      options[:item],
      "--fields",
      options[:field],
      "--reveal"
    ])
  end
end
