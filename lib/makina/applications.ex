defmodule Makina.Applications do
  @moduledoc false

  use Makina.Infrastructure.RemoteCommand
  require Logger

  alias Makina.Infrastructure.Docker
  alias Makina.Infrastructure.IO

  alias Makina.Servers
  alias Makina.Models.Server
  alias Makina.Models.Application

  @doc """
  Deploys a list of application on a list of servers

  Connection is established before triggering applications deployment
  and disconnection happens when all applications have been deployed.
  """
  def deploy_applications(servers, applications)
      when is_list(servers) and is_list(applications) do
    for server <- servers do
      Servers.with_connection!(server, fn s ->
        Enum.map(applications, &deploy_application(s, &1))
      end)
    end
  end

  @doc """
  Stops all provided applications in all servers

  `servers` should be a list of servers to stop applications into.

  Servers and applications are processed sequentially.
  """
  def stop_applications(servers, applications)
      when is_list(servers) and is_list(applications) do
    for server <- servers do
      Servers.with_connection!(server, fn s ->
        Enum.map(applications, &stop_application(s, &1))
      end)
    end
  end

  @doc """
  Removes all provided applications in all servers

  `servers` should be a list of servers to stop applications into.

  Servers and applications are processed sequentially.
  """
  def remove_applications(servers, applications)
      when is_list(servers) and is_list(applications) do
    for server <- servers do
      Servers.with_connection!(server, fn s ->
        Enum.map(applications, &remove_application(s, &1))
      end)
    end
  end

  @doc """
  Deploys an application on a specific server

  Note: The server has to have a connection at this point.
  """
  def deploy_application(%Server{} = server, %Application{} = app) do
    do_deploy(server, app)
  end

  @doc """
  Stops an application on a given server
  """
  def stop_application(%Server{} = server, %Application{} = app) do
    do_stop(server, app)
  end

  @doc """
  Updates a running application

  The update process goes as follow:
  * First makina checks if the remote application should be updated
  * Stale containers for the application is removed if exist from previous update
  * The currently running container is marked as stale
  * New version is started
  * Stale container is stopped

  ### When an application can be updated?
  Makina determines whether an application should be updated based on an internal hash.
  The hash is calculated on all fields that a user can change, while private fields are
  ignored.

  When using utilities functions that are found in `Application` makina is able to
  calculate the hash and therefore to know if the app is changed.
  The same functions are used by the DSL Makinafile is composed of.

  This is done to avoid re-deployments of up-to-date containers at the same time without
  having some shared state somewhere. This should guarentee that if 2 users with the
  same version of a Makinafile trigger an update the same outcome is expected.
  """
  def update_application(%Server{} = server, %Application{} = app) do
    do_update(server, app)
  end

  @doc """
  Removes an a application from the server
  """
  def remove_application(%Server{} = server, %Application{} = app) do
    Docker.remove(server, app) |> execute_command()
  end

  @doc """
  Same as `remove_application/2` except it accepts a container name
  """
  def remove_application_by_name(%Server{} = server, name) when is_binary(name) do
    Docker.remove(server, name) |> execute_command()
  end

  @doc """
  Returns the running information from Docker on a remote application
  """
  def inspect_deployed_application(%Server{} = server, %Application{} = app) do
    Docker.inspect(server, app) |> execute_command()
  end

  defp mark_app_as_stale(%Server{} = server, %Application{} = app) do
    Docker.rename_container(server, app, suffix: "__stale") |> execute_command()
  end

  defp stop_stale_app(%Server{} = server, %Application{} = app) do
    Docker.stop(server, "#{Docker.app_name(app)}__stale") |> execute_command()
  end

  defp remove_stale_app(%Server{} = server, %Application{} = app) do
    stale_name = "#{Docker.app_name(app)}__stale"

    case Docker.inspect(server, stale_name) |> execute_command() do
      {:ok, nil} ->
        {:ok, :no_app}

      {:ok, _} ->
        remove_application_by_name(server, stale_name)

      error ->
        error
    end
  end

  defp do_update(%Server{} = server, %Application{} = app) do
    IO.puts(" Updating \"#{app.name}\"")

    with {:ok, :update} <- check_update_required(server, app),
         {:ok, _} <- remove_stale_app(server, app),
         {:ok, _} <- mark_app_as_stale(server, app),
         {:ok, _} <- do_deploy(server, app),
         {:ok, _} <- stop_stale_app(server, app) do
      {:ok, :updated}
    else
      {:ok, :no_update} ->
        IO.puts(" No update needed for \"#{app.name}\"")
        {:ok, :no_update}

      error ->
        error
    end
  end

  defp check_update_required(server, app) do
    case inspect_deployed_application(server, app) do
      {:ok, container} ->
        running_hash = get_in(container, ["Config", "Labels", "org.makina.app.hash"])

        cond do
          is_nil(running_hash) -> {:error, :no_app}
          String.to_integer(running_hash) != app.__hash__ -> {:ok, :update}
          String.to_integer(running_hash) == app.__hash__ -> {:ok, :no_update}
        end

      {:error, _} ->
        {:error, :no_app}
    end
  end

  defp do_stop(%Server{} = server, %Application{} = app) do
    IO.puts(" Stopping \"#{app.name}\"")

    Docker.stop(server, app) |> execute_command()
  end

  def do_deploy(%Server{} = server, %Application{} = app) do
    IO.puts(" Deploying \"#{app.name}\"")

    with {:ok, _} <- maybe_login_to_registry(server, app),
         {:ok, nil} <- ensure_app_not_running(server, app) do
      Logger.debug("No current instances of #{app.name} running, deploying")

      Docker.run(server, app) |> execute_command()
    else
      {:ok, _container} ->
        Logger.debug("A version of #{app.name} is already running, skipping.")
        do_update(server, app)

      {:error, reason} ->
        {:error, reason}

      err ->
        err
    end
  end

  defp ensure_app_not_running(server, app) do
    inspect_deployed_application(server, app)
  end

  defp maybe_login_to_registry(server, app) do
    if Application.private_docker_registry?(app) do
      Docker.login(server, app) |> execute_command()
    else
      {:ok, :no_login}
    end
  end
end
