defmodule Makina.Cli.Commands.Test do
  @behaviour Makina.Cli.Command

  alias Makina.SSH

  def name(), do: "test"

  def short_description(),
    do: "Tests whether nodes configured inside the Makinafile can be successully reached"

  def exec(_arguments, _options) do
    makinafile = Path.join(File.cwd!(), "Makinafile.exs")
    Makina.File.compile_build_file(makinafile)
    servers = Makina.File.fetch_servers()

    Owl.ProgressBar.start(
      id: :server_tests,
      label: "Testing servers",
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
      IO.puts(Owl.Data.tag("Cannot reach some servers", :red))

      :error
    else
      IO.puts("All servers are reachable ✅")

      :ok
    end
  end

  def options() do
    []
  end

  defp test_with_errors?(results),
    do: Enum.any?(results, fn r -> elem(r, 0) == :error end)
end
