defmodule Makina.Cli.Command do
  @callback exec(arguments :: list(), options :: list()) :: :ok | :error
  @callback options() :: list(keyword())
end
