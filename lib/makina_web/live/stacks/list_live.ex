defmodule MakinaWeb.Stacks.ListLive do
  use MakinaWeb, :live_view

  import MakinaWeb.CoreComponents

  alias Makina.Stacks

  def render(assigns) do
    ~H"""
    <.header class="text-2xl">
      Stacks
      <:actions>
        <div class="hs-dropdown relative inline-flex">
          <button
            id="hs-dropdown-custom-icon-trigger"
            type="button"
            class="hs-dropdown-toggle flex justify-center items-center size-9 text-sm font-semibold rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-900 dark:border-gray-700 dark:text-white dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
          >
            <svg
              class="flex-none size-4 text-gray-600"
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <circle cx="12" cy="12" r="1" /><circle cx="12" cy="5" r="1" /><circle
                cx="12"
                cy="19"
                r="1"
              />
            </svg>
          </button>

          <div
            class="hs-dropdown-menu transition-[opacity,margin] duration hs-dropdown-open:opacity-100 opacity-0 hidden min-w-60 bg-white shadow-md rounded-lg p-2 mt-2 dark:bg-gray-800 dark:border dark:border-gray-700"
            aria-labelledby="hs-dropdown-custom-icon-trigger"
          >
            <.link
              class="flex items-center gap-x-3.5 py-2 px-3 rounded-lg text-sm text-gray-800 hover:bg-gray-100 focus:outline-none focus:bg-gray-100 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-gray-300 dark:focus:bg-gray-700"
              navigate={~p"/stacks/create"}
            >
              Create New
            </.link>
          </div>
        </div>
      </:actions>
    </.header>
    <section :if={@stacks != []} class="grid grid-cols-4 gap-4 pt-5">
      <.card
        :for={stack <- @stacks}
        title={stack.name}
        description={stack.description}
        cta_text="Go to stack"
        cta_url={~p"/stacks/#{stack.id}"}
      />
    </section>
    """
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:stacks, Stacks.list_applications())
    |> wrap_ok()
  end
end
