defmodule Makina.Cli.Commands.Init do
  @behaviour Makina.Cli.Command

  alias Owl.IO

  def name(), do: "init"

  def short_description(),
    do: "Initializes the current folder with an empty Makinafile"

  def help,
    do: """
    Makina
    Initialization command

    Creates a Makinafile.exs in the current working directory or to a given <PATH>

    makina init [PATH]

    Arguments:
    * PATH - An optional path where to create the Makinafile. Should be a path, without file name.
    """

  def exec(arguments, _options) do
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

    :ok
  end

  def options() do
    []
  end
end
