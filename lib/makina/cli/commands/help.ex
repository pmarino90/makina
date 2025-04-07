defmodule Makina.Cli.Commands.Help do
  @behaviour Makina.Cli.Command

  alias Owl.IO

  def name, do: "Help"
  def short_description, do: "Prints the general help message"
  def help, do: general_help()

  def exec(arguments \\ [], _options) do
    command = List.first(arguments)

    message = if is_nil(command), do: general_help(), else: command_help(command)

    IO.puts(message)

    :ok
  end

  def options() do
    []
  end

  defp command_help(command) when is_binary(command) do
    command = String.to_atom(command)

    if Map.has_key?(Makina.Cli.commands(), command) do
      module = Map.get(Makina.Cli.commands(), command)

      module.help()
    else
      general_help()
    end
  end

  defp general_help() do
    """
    Makina
    Paolo Marino
    A simple application manager for self-hosted environments.

    To see the specific help for each command run:

    makina help <COMMAND>

    Commands:
    #{commands_short_description()}
    """
  end

  defp commands_short_description() do
    Makina.Cli.commands()
    |> Map.values()
    |> Enum.map_join("\n", fn c -> "#{c.name()}    #{c.short_description()}" end)
  end
end
