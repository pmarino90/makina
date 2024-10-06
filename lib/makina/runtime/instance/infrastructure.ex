defmodule Makina.Runtime.Instance.Infrastructure do
  alias Phoenix.PubSub
  alias Makina.Runtime.Instance.State

  require Logger

  def subscribe_to_service_events(service) do
    PubSub.subscribe(Makina.PubSub, "system::service::#{service.id}")
  end

  @doc """
  Defines a unified log entry point.
  This function can both log into Makina's console and also the container's 
  log stream (generally visible from the Web UI.
  """
  def log(%State{} = state, entry, opts \\ []) do
    with_prompt = Keyword.get(opts, :with_prompt, true)
    global_log = Keyword.get(opts, :global_log, true)

    formatted_entry = if with_prompt, do: format_log_with_prompt(entry), else: entry

    PubSub.broadcast(
      Makina.PubSub,
      "system::service::#{state.service.id}::logs",
      {:log_entry, IO.chardata_to_string(formatted_entry)}
    )

    if global_log, do: Logger.info(entry)
  end

  defp format_log_with_prompt(entry) do
    IO.ANSI.format([
      :cyan,
      :bright,
      "[Makina][Runtime]",
      " ",
      entry,
      "\n\r"
    ])
  end
end
