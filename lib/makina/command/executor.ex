defmodule Makina.Command.Executor do
  @callback execute(cmd :: struct()) ::
              {:ok, term()} | {:error, term()} | :timeout
end
