defmodule Makina.Cli.Commands.Test do
  @behaviour Makina.Cli.Command

  import Makina.Cli.Utils

  alias Makina.SSH
  alias Makina.IO

  def name(), do: "test"

  def short_description(),
    do: "Tests whether nodes configured inside the Makinafile can be successully reached"

  def help,
    do: """
    Makina
    Test command

    Given the Makinafile the command tries to connect to those servers defined in it and reports the result.

    makina test [OPTIONS]

    Options:
    * --file - The path to a Makinafile, if not provided the command will look for it in the current folder.
    """

  def exec(_arguments, options) do
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

  def options() do
    [file: :string]
  end

  defp test_with_errors?(results),
    do: Enum.any?(results, fn r -> elem(r, 0) == :error end)
end
