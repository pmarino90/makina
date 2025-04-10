defmodule Makina.Cli.Commands.Server do
  @behaviour Makina.Cli.Command

  import Makina.Cli.Utils

  require Logger
  alias Makina.SSH
  alias Makina.IO
  alias Makina.Servers

  @sub_commands ~w[test prepare]a

  def name(), do: "server"

  def short_description(),
    do: "Tests whether nodes configured inside the Makinafile can be successully reached"

  def help,
    do: """
    Makina
    Server command

    Exposes server related commands.

    Usage:
    makina server <SUB COMMAND> [OPTIONS]

    Sub-commands:
    test      Tests the connection between the current host and all servers defined in the Makinafile.

    prepare   Installs system services on each server in the list if they are not there already.

    Global options:
    * --file - The path to a Makinafile, if not provided the command will look for it in the current folder.
    """

  def exec(arguments, options) do
    extract_subcommand(arguments)
    |> sub_command(options)
  end

  def options() do
    [file: :string]
  end

  defp sub_command(:prepare, options) do
    ctx =
      makinafile(options)
      |> fetch_context()

    servers = ctx.servers

    for server <- servers do
      Servers.prepare_server(server, ctx)
    end

    :ok
  end

  defp sub_command(:test, options) do
    ctx =
      makinafile(options)
      |> fetch_context()

    servers = ctx.servers

    Owl.ProgressBar.start(
      id: :server_tests,
      label: "Testing servers connectivity",
      total: Enum.count(servers)
    )

    results =
      for server <- servers do
        response =
          SSH.connect(
            server.host,
            user: server.user,
            password: server.password,
            port: server.port
          )

        case response do
          {:ok, conn_ref} ->
            SSH.disconnect(conn_ref)
            Owl.ProgressBar.inc(id: :server_tests)

            {:ok, server}

          {:error, _reason} ->
            Owl.ProgressBar.inc(id: :server_tests)

            {:error, server}
        end
      end

    Owl.LiveScreen.await_render()

    if test_with_errors?(results) do
      IO.puts_error("Cannot reach some servers")

      :error
    else
      IO.puts_success("All servers are reachable ✅")

      :ok
    end
  end

  defp sub_command(:help, _options) do
    IO.puts(help())
  end

  defp extract_subcommand([]) do
    :help
  end

  defp extract_subcommand([sub_command | _rest]) do
    sub_command = sub_command |> String.to_atom()

    if Enum.member?(@sub_commands, sub_command), do: sub_command, else: :help
  end

  defp test_with_errors?(results),
    do: Enum.any?(results, fn r -> elem(r, 0) == :error end)
end
