defmodule Makina.Cli.Commands.Debug do
  @behaviour Makina.Cli.Command

  import Makina.Cli.Utils

  def name, do: "debug"

  def short_description() do
    "Command to carry out different debugging operations, should not be neened most of of the times"
  end

  def help,
    do: """
    Makina
    debug command

    Outputs various debug information based on the options provided

    makina debug [OPTIONS]

    Options:
    * --file - The path to a Makinafile, if not provided the command will look for it in the current folder.
    * --context - Dumps the whole context collected from interpreting a Makinafile
    """

  def options() do
    [file: :string, context: :boolean]
  end

  def exec(_arguments, options) do
    case options do
      [context: true] ->
        makinafile = makinafile(options)

        ctx =
          Makina.File.read_makina_file!(makinafile)
          |> Makina.File.evaluate_makina_file()
          |> Makina.File.collect_makina_file_context()

        IO.puts(JSON.encode!(ctx))
    end
  end
end
