defmodule Makina.Cli.Commands.Help do
  @behaviour Makina.Cli.Command

  alias Owl.IO

  def name, do: "Help"
  def short_description, do: "Prints the general help message"

  def exec(_arguments, _options) do
    message = """
    Makina
    Paolo Marino
    A simple application manager for self-hosted environments.

    Usage: Makina <COMMAND> [ARGUMENTS] [OPTIONS]

    Commands:
    #{commands_short_description()}

    Options:
     -h, --help       Print help
    """

    IO.puts(message)

    :ok
  end

  def options() do
    []
  end

  defp commands_short_description() do
    Makina.Cli.commands()
    |> Map.values()
    |> Enum.map(fn c -> "#{c.name()}    #{c.short_description()}" end)
    |> Enum.join("\n")
  end
end
