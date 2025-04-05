defmodule Makina.Cli.Utils do
  @moduledoc false

  def makinafile([]) do
    Path.join(File.cwd!(), "Makinafile.exs")
  end

  def makinafile(options) do
    if Keyword.has_key?(options, :file) do
      options[:file]
    else
      makinafile([])
    end
  end

  def fetch_context(makinafile) do
    Makina.File.read_makina_file!(makinafile)
    |> Makina.File.evaluate_makina_file()
    |> Makina.File.collect_makina_file_context()
  end
end
