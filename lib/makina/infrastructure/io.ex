defmodule Makina.Infrastructure.IO do
  alias Owl.IO

  def puts_success(message) do
    IO.puts(Owl.Data.tag(message, :green), :stdio)
  end

  def puts_error(message) do
    IO.puts(Owl.Data.tag(message, :red), :stderr)
  end

  def puts(message, device \\ :stdio) do
    IO.puts(message, device)
  end
end
