defmodule Makina.Runtime.Instance.State do
  @moduledoc """
  Instance's internal state
  """

  alias Makina.Stacks.{Stack, Service}

  defstruct stack: %Stack{},
            service: %Service{},
            instance_number: 1,
            running_port: 0,
            running_state: :new,
            auto_boot: true,
            assigns: %{}

  @type t :: %__MODULE__{
          stack: %Stack{},
          service: %Service{},
          instance_number: number(),
          running_port: number(),
          running_state: :new | :configuring | :starting | :running | :stopping | :stopped,
          auto_boot: boolean(),
          assigns: map()
        }
end
