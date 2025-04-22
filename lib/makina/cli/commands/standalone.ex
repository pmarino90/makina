defmodule Makina.Cli.Commands.Standalone do
  @behaviour Makina.Cli.Command

  import Makina.Cli.Utils

  alias Makina.Infrastructure.IO
  alias Makina.Applications

  @sub_commands ~w[deploy stop]a

  def name(), do: "standalone"

  def short_description(),
    do: "Manage standalone applications defined in the Makinafile"

  def help,
    do: """
    Makina
    Standalone applications management command

    Manages all standalone applications found in the current Makinafile.

    Usage:
    makina standalone <SUB COMMAND> [OPTIONS]

    Sub-commands:
    deploy    Deploys all standalone applications defined in the Makinafile.

    Options:
    * --file - The path to a Makinafile, if not provided the command will look for it in the current folder.
    """

  def exec(arguments, options) do
    extract_subcommand(arguments)
    |> sub_command(options)
  end

  def options() do
    [file: :string]
  end

  defp sub_command(:deploy, options) do
    ctx =
      makinafile(options)
      |> fetch_context()

    servers = ctx.servers

    deployment_result =
      Applications.deploy_applications(servers, ctx.standalone_applications)

    case deployment_errors?(deployment_result) do
      true ->
        IO.puts_error("There were errors while deploying some applications.")

        :ok

      false ->
        IO.puts_success("All applications have been deployed!")
    end

    :ok
  end

  defp sub_command(:stop, options) do
    ctx =
      makinafile(options)
      |> fetch_context()

    servers = ctx.servers

    deployment_result =
      Applications.stop_applications(servers, ctx.standalone_applications)

    case deployment_errors?(deployment_result) do
      true ->
        IO.puts_error("There were errors while stopping some applications.")

        :ok

      false ->
        IO.puts_success("All applications have been stopped!")
    end

    :ok
  end

  defp extract_subcommand([sub_command | _rest]) do
    sub_command = sub_command |> String.to_atom()

    if Enum.member?(@sub_commands, sub_command), do: sub_command, else: :help
  end

  defp deployment_errors?(results) do
    results
    |> List.flatten()
    |> Enum.any?(fn {res, _data} -> res == :error end)
  end
end
