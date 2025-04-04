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
end
