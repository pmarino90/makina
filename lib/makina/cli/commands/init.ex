defmodule Makina.Cli.Commands.Init do
  @behaviour Makina.Cli.Command

  alias Owl.IO

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
