defmodule Makina.File do
  def compile_build_file(path) do
    {_term, bindings} = Code.eval_file(path)

    bindings
  end
end
