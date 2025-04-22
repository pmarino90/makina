defmodule Makina.Infrastructure.RemoteCommand.Executor do
  @moduledoc false
  @callback execute(cmd :: struct()) ::
              {:ok, term()} | {:error, term()} | :timeout
end
