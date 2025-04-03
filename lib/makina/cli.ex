defmodule Makina.Cli do
  def start(_, [:test]) do
    {:ok, self()}
  end

  def start(_, _args) do
    {command, _arguments, _options} = parse_command(Burrito.Util.Args.argv())

    case command(command) do
      {:ok, out} -> IO.puts(out)
      {:error, out} -> IO.puts(:stderr, out)
    end

    System.halt(0)

    :ok
  end

  def command(command, options \\ [])

  def command(:help, _options) do
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

    {:ok, message}
  end

  def command(:init, _options) do
    {:ok, "TBD"}
  end

  def command(_cmd, options), do: command(:help, options)

  @doc """
  Parses a list of cli args and returns a tuple in the form of `{command, arguments, options}`
  """
  def parse_command([]) do
    {:help, [], []}
  end

  def parse_command([command | _options]) do
    {String.to_atom(command), [], []}
  end
end
