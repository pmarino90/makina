defmodule Makina.Cli.Commands.Deploy do
  @behaviour Makina.Cli.Command

  import Makina.Cli.Utils

  alias Makina.IO

  def name(), do: "deploy"

  def short_description(),
    do: "Deploys all applications found in a Makinafile according to their definition."

  def help,
    do: """
    Makina
    Deploy command

    Deploys all applications found in a Makinafile according to their definition.
    Applications defined inside a `standalone` block will be deployed independently from
    each other and a failure won't affect other deployments.

    makina deploy [OPTIONS]

    Options:
    * --file - The path to a Makinafile, if not provided the command will look for it in the current folder.
    """

  def exec(_arguments, options) do
    ctx =
      makinafile(options)
      |> fetch_context()

    servers = ctx[:servers]

    deployment_result =
      Makina.deploy_standalone_applications(servers, ctx[:standalone_applications])

    case deployment_errors?(deployment_result) do
      true ->
        IO.puts_error("There were errors while deploying some applications.")

        :ok

      false ->
        IO.puts_success("All applications have been deployed!")
    end

    :ok
  end

  def options() do
    [file: :string]
  end

  defp deployment_errors?(results) do
    results
    |> List.flatten()
    |> Enum.any?(fn {res, _data} -> res == :error end)
  end
end
