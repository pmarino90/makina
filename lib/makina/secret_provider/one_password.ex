defmodule Makina.SecretProvider.OnePassword do
  @moduledoc false

  require Logger

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
    case token_or_sign_in() do
      :error ->
        raise """
        Could not get the session token from 1Password.
        """

      :timeout ->
        raise """
        Could not get the session token from 1Password.
        """

      session_token when is_binary(session_token) ->
        Process.put(:one_password_session_token, session_token)

        System.cmd("op", [
          "read",
          "op://#{options[:reference]}",
          "--no-newline",
          "--force",
          "--session=#{session_token}"
        ])
    end
  end

  defp token_or_sign_in() do
    case Process.get(:one_password_session_token) do
      nil ->
        signin()

      token ->
        token
    end
  end

  # although everything is fine this is required because probably there are some
  # mismatching specs for Owl.IO.input
  @dialyzer {:no_return, signin: 0}
  defp signin do
    port = Port.open({:spawn, "op signin --raw"}, [:binary, :exit_status])

    password =
      Owl.IO.input(label: "Insert password to unlock 1Password: ", secret: true)

    Port.command(port, password <> "\n")

    wait_for_token(port)
  end

  @spec wait_for_token(port()) :: String.t() | :error | :timeout
  defp wait_for_token(port) do
    receive do
      {^port, {:data, data}} ->
        case String.trim(data) do
          session_token when byte_size(session_token) > 0 ->
            session_token

          _ ->
            wait_for_token(port)
        end

      {^port, {:exit_status, status}} when status != 0 ->
        Logger.debug("op signin command exited with status #{status}")
        :error

      _ ->
        wait_for_token(port)
    after
      60 * 1000 ->
        :timeout
    end
  end
end
