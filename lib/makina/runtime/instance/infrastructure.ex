defmodule Makina.Runtime.Instance.Infrastructure do
  alias Phoenix.PubSub

  def subscribe_to_service_events(service) do
    PubSub.subscribe(Makina.PubSub, "system::service::#{service.id}")
  end
end
