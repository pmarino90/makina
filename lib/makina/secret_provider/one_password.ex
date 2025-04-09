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
    session_token =
      System.get_env("OP_SESSION_#{options[:account]}") ||
        raise """
        Makina could not find the Session Token.

        In order to fetch secrets from your vault Makina requires a session token.
        When you run eval $(op signin) 1Password automatically sets the session token for you.

        Also make sure that when providing the reference to which secret you want to fetch, you specify as account the ID, which can be found by running: "op accounts list" or op whoami .
        """

    System.cmd("op", [
      "read",
      "op://#{options[:reference]}",
      "--no-newline",
      "--force",
      "--session=#{session_token}"
    ])
  end
end
