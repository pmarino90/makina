defmodule Makina.Cli do
  alias Makina.Cli.Commands

  alias Owl.IO

  def commands do
    %{
      help: Commands.Help,
      init: Commands.Init,
      test: Commands.Test,
      debug: Commands.Debug,
      deploy: Commands.Deploy
    }
  end

  def start(_, [:test]) do
    {:ok, self()}
  end

  def start(_, _args) do
    try do
      {command, arguments, options} = parse_command(Burrito.Util.Args.argv())

      case command(command, arguments, options) do
        :ok -> System.halt(0)
        :error -> System.halt(1)
      end
    rescue
      err ->
        IO.puts(
          Owl.Data.tag(
            "#{Exception.message(err)}",
            :red
          ),
          :stderr
        )

        System.halt(1)
    end

    :ok
  end

  def command(command, arguments \\ [], options \\ []) do
    module = Map.get(commands(), command, Commands.Help)

    module.exec(arguments, options)
  end

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
        switches: get_command_options(command)
      )

    {command, arguments, options}
  end

  defp get_command_options(command) do
    module = Map.get(commands(), command, nil)

    if is_nil(module), do: [], else: module.options()
  end
end
