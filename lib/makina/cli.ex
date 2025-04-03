defmodule Makina.Cli do
  alias Owl.IO

  def start(_, [:test]) do
    {:ok, self()}
  end

  def start(_, _args) do
    {command, _arguments, _options} = parse_command(Burrito.Util.Args.argv())

    case command(command) do
      {:ok, out} -> IO.puts(out)
      {:error, out} -> IO.puts(out, :stderr)
    end

    System.halt(0)

    :ok
  end

  def command(command, arguments \\ [], options \\ [])

  def command(:help, _arguments, _options) do
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

  def command(:init, arguments, _options) do
    destination_path = List.first(arguments, File.cwd!())
    file = Path.join(destination_path, "Makinafile.exs")

    if File.exists?(file) do
      IO.puts("File already exists, skipping!")
    else
      File.write(file, """
      # Hello
      """)

      IO.puts("Makinafile created at #{Path.relative_to_cwd(file)} ✅")
    end

    {:ok, ""}
  end

  def command(_cmd, arguments, options), do: command(:help, arguments, options)

  @doc """
  Parses a list of cli args and returns a tuple in the form of `{command, arguments, options}`
  """
  def parse_command([]) do
    {:help, [], []}
  end

  def parse_command([command | rest]) do
    command = String.to_atom(command)

    {options, arguments, _invalid} =
      OptionParser.parse(rest,
        switches: options_for(command)
      )

    {command, arguments, options}
  end

  defp options_for(_cmd), do: []
end
