defmodule Makina.Cli.Commands.Apps do
  @behaviour Makina.Cli.Command

  import Makina.Cli.Utils

  alias Makina.Infrastructure.IO
  alias Makina.Applications

  @sub_commands ~w[deploy stop remove]a

  def name(), do: "apps"

  def short_description(),
    do: "Manage applications defined in the Makinafile"

  def help,
    do: """
    Makina
    Applications management command

    Manages all applications found in the current Makinafile.

    Usage:
    makina apps <SUB COMMAND> [OPTIONS]

    Sub-commands:
    deploy    Deploys all applications defined in the Makinafile.
    stop      Stops all applications.
    remove    Removes apps from servers.

    Options:
    * --app   Specifies which app to apply the command to.
    * --file  The path to a Makinafile, if not provided the command will look for it in the current folder.
    """

  def exec(arguments, options) do
    extract_subcommand(arguments)
    |> sub_command(options)
  end

  def options() do
    [file: :string, app: :string]
  end

  defp sub_command(:deploy, options) do
    ctx =
      makinafile(options)
      |> fetch_context()

    servers = ctx.servers
    apps = filter_apps_from_options(ctx.applications, options)
    deployment_result = do_deploy(servers, apps)

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
    apps = filter_apps_from_options(ctx.applications, options)
    deployment_result = do_stop(servers, apps)

    case deployment_errors?(deployment_result) do
      true ->
        IO.puts_error("There were errors while stopping some applications.")

        :ok

      false ->
        IO.puts_success("All applications have been stopped!")
    end

    :ok
  end

  defp sub_command(:remove, options) do
    ctx =
      makinafile(options)
      |> fetch_context()

    servers = ctx.servers
    apps = filter_apps_from_options(ctx.applications, options)
    deployment_result = do_remove(servers, apps)

    case deployment_errors?(deployment_result) do
      true ->
        IO.puts_error("There were errors while stopping some applications.")

        :ok

      false ->
        IO.puts_success("All applications have been stopped!")
    end

    :ok
  end

  defp sub_command(_, _options) do
    IO.puts(help())

    :ok
  end

  defp do_deploy(_servers, []) do
    raise """
    The selected application cannot be found in the Makinafile.
    """
  end

  defp do_deploy(servers, apps) do
    Applications.deploy_applications(servers, apps)
  end

  defp do_stop(_servers, []) do
    raise """
    The selected application cannot be found in the Makinafile.
    """
  end

  defp do_stop(servers, apps) when is_list(apps) do
    Applications.stop_applications(servers, apps)
  end

  defp do_remove(_servers, []) do
    raise """
    The selected application cannot be found in the Makinafile.
    """
  end

  defp do_remove(servers, apps) when is_list(apps) do
    Applications.remove_applications(servers, apps)
  end

  defp filter_apps_from_options(apps, options) do
    selected_app = Keyword.get(options, :app, :all)

    if selected_app == :all do
      apps
    else
      Enum.filter(apps, fn a -> a.name == selected_app end)
    end
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
