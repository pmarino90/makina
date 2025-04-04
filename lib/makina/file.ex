defmodule Makina.File do
  def read_makina_file!(path) do
    File.read!(path)
  end

  def evaluate_makina_file(content) do
    {:ok, env} =
      __ENV__
      |> Macro.Env.define_import([line: 1], Makina.DSL)

    Code.eval_string(content, [], env)
  end

  def collect_makina_file_context({nil, []}) do
    raise """
    Makina could not find the correct information within the provided file.
    Is it possible that is still empty?
    """
  end

  def collect_makina_file_context({term, _binding}) do
    module = elem(term, 1)

    if Kernel.function_exported?(module, :collect_context, 0) do
      module.collect_context()
    else
      raise """
      Makina could not find the correct information within the provided file.
      Ensure that your definitions are contained inside a makina block like so:

      makina do
        server host: "example.com", user: "user"
      end

      Also ensure that no other Elixir modules are defined within the file.
      """
    end
  end
end
