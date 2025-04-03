defmodule Makina.Cli.Command do
  @callback exec(arguments :: list(), options :: list()) :: :ok | :error
  @callback options() :: list(keyword())

  @callback name() :: String.t()
  @callback short_description() :: String.t()
end
