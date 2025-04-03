defmodule Makina.Cli.Commands.Help do
  @behaviour Makina.Cli.Command

  alias Owl.IO

  def exec(_arguments, _options) do
    message = """
    Makina
    Paolo Marino
    A simple application manager for self-hosted environments.

    Usage: Makina <COMMAND> [OPTIONS]

    Arguments:
    help    Prints the general help message
    init    Initializes the current repository with an empty Makinafile
    test    Tests whether nodes configured inside the Makinafile can be successully reached

    Options:
     -h, --help       Print help
    """

    IO.puts(message)

    :ok
  end

  def options() do
    []
  end
end
