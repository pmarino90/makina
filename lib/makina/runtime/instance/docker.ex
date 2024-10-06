defmodule Makina.Runtime.Instance.Docker do
  @moduledoc """
  Docker implementation for an Instance.

  This module is responsible of the whole lifecycle of an instance
  whose runtime is Docker.
  """
  use Makina, :instance

  alias Makina.{Docker, Vault}

  def configure(%State{stack: stack, service: service} = state) do
    state =
      state
      |> assign(container_name: "#{full_service_name(%{stack: stack, service: service})}-1")
      |> assign(network_name: "#{stack.slug}-network")

    state
  end

  def before_run(%State{} = state) do
    state
    |> fetch_dependencies()
    |> create_stack_network()
    |> create_container()
    |> maybe_expose_container()
  end

  def on_run(%State{} = state) do
    state
    |> start_container()
  end

  def on_stop(_args), do: raise("Not Implemented")
  def expose_instance(_args), do: raise("Not Implemented")

  defp fetch_dependencies(%{service: service} = state) do
    progress_update = fn {:data, data}, {req, res} ->
      log(:info, data)

      {:cont, {req, res}}
    end

    params = [
      docker: %{
        "fromImage" => full_image_reference(service)
      },
      on_progress: progress_update
    ]

    params =
      if service.image_registry_user,
        do: Keyword.put(params, :headers, x_registry_auth: build_auth_header(service)),
        else: params

    Docker.create_image(params)
    state
  end

  defp full_service_name(%{stack: stack, service: service}), do: "#{stack.slug}-#{service.slug}"

  defp full_image_reference(service) do
    registry_host =
      if service.image_registry == "hub.docker.com", do: "", else: "#{service.image_registry}/"

    "#{registry_host}#{service.image_name}:#{service.image_tag}"
  end

  defp build_auth_header(service) do
    auth_obj = %{
      "username" => service.image_registry_user,
      "password" => Vault.decrypt!(service.image_registry_encrypted_password),
      "serveraddress" => "https://#{service.image_registry}"
    }

    Base.encode64(Jason.encode!(auth_obj))
  end

  defp create_stack_network(%State{} = state) do
    network_name = state.assigns.network_name

    case Docker.inspect_network(network_name) do
      {:ok, %Req.Response{status: 404}} ->
        Logger.info("Creating network for Stack")
        Docker.create_network!(network_name)
        state

      {:ok, _network_data} ->
        Logger.info("Stack's network exists, skip creation")
        state
    end
  end

  defp maybe_expose_container(%State{service: service} = state) do
    if service.expose_service do
      Docker.connect_network!(state.assigns.container_name, "makina_web-net")
      state
    else
      state
    end
  end

  defp create_container(%State{service: service, assigns: assigns} = state) do
    Logger.info("Creating container #{assigns.container_name}")

    network_name = assigns.network_name

    assigns.container_name
    |> Docker.create_container!(%{
      "Image" => full_image_reference(service),
      "Env" => build_env_variables(state),
      "Tty" => true,
      "HostConfig" => %{
        "Mounts" => build_docker_volumes_mount(state),
        "NetworkMode" => network_name
      },
      "Labels" => build_docker_labels(state)
    })

    state
  end

  defp start_container(state) do
    container_name = state.assigns.container_name

    Logger.info("Starting container #{container_name}")

    container_name
    |> Docker.start_container!()

    state
  end

  defp monitor_and_collect_console_out(state) do
    entry_collector = fn {:data, data}, {req, res} ->
      # log(state, data, with_prompt: false)

      {:cont, {req, res}}
    end

    {:ok, pid} =
      Task.Supervisor.start_child(Makina.Runtime.TaskSupervisor, fn ->
        Docker.logs_for_container!(state.container_name, entry_collector)
      end)

    Process.link(pid)

    state
  end

  defp build_env_variables(%{service: service, running_port: port}) do
    vars =
      service.environment_variables
      |> Enum.map(fn e -> "#{e.name}=#{get_env_variable_value(e)}" end)

    if service.expose_service do
      ["PORT=#{port}"] ++ vars
    else
      vars
    end
  end

  defp get_env_variable_value(var) do
    case var.type do
      :secret -> Vault.decrypt!(var.encrypted_value)
      _ -> var.text_value
    end
  end

  defp build_docker_volumes_mount(state) do
    stack = state.stack
    service = state.service

    service.volumes
    |> Enum.map(fn v ->
      %{
        "Target" => v.mount_point,
        "Source" => "#{stack.slug}-#{service.slug}-#{v.name}",
        "Type" => "volume",
        "ReadOnly" => false
      }
    end)
  end

  defp build_docker_labels(%{stack: stack, service: service} = state) do
    labels = %{
      "com.makina.app" => stack.slug,
      "com.makina.service" => service.slug
    }

    {labels, state}
    |> maybe_put_traefik_basic_labels()
    |> maybe_put_https_labels()
    |> elem(0)
  end

  defp maybe_put_traefik_basic_labels({labels, state}) do
    service = state.service

    if service.expose_service do
      domains =
        service.domains
        |> Enum.map(fn d -> "`#{d.domain}`" end)
        |> Enum.join(",")

      labels =
        Map.merge(
          labels,
          %{
            "traefik.enable" => "true",
            "traefik.http.middlewares.#{full_service_name(state)}.compress" => "true",
            "traefik.http.routers.#{full_service_name(state)}.rule" => "Host(#{domains})",
            "traefik.http.services.#{full_service_name(state)}.loadBalancer.server.port" =>
              "#{state.running_port}"
          }
        )

      {labels, state}
    else
      {labels, state}
    end
  end

  defp maybe_put_https_labels({labels, state}) do
    service = state.service
    config = Application.get_env(:makina, Makina.Runtime)

    if service.expose_service and Keyword.get(config, :enable_https, false) do
      labels =
        Map.put(
          labels,
          "traefik.http.routers.#{full_service_name(state)}.tls.certresolver",
          "letsencrypt"
        )

      {labels, state}
    else
      {labels, state}
    end
  end
end
