defmodule Makina.Cli do
  def start(_, [:test]) do
    {:ok, self()}
  end

  def start(_, _args) do
    dbg()
    IO.puts("Hello")

    System.halt(0)

    :ok
  end
end
