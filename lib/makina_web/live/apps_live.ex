defmodule MakinaWeb.AppsLive do
  use MakinaWeb, :live_view

  import MakinaWeb.CoreComponents

  alias Makina.Apps

  def render(assigns) do
    ~H"""
    <.header class="text-2xl">
      Apps
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
              navigate={~p"/apps/create"}
            >
              Create New
            </.link>
          </div>
        </div>
      </:actions>
    </.header>
    <section :if={@apps != []} class="grid grid-cols-4 gap-4 pt-5">
      <section
        :for={app <- @apps}
        class="flex flex-col bg-white border border-gray-200 shadow-sm rounded-xl p-4 md:p-5 dark:bg-slate-900 dark:border-gray-700 dark:text-gray-400"
      >
        <h4><%= app.name %></h4>
        <p class="mt-2 text-gray-500 dark:text-gray-400">
          <%= app.description %>
        </p>

        <.link
          navigate={~p"/apps/#{app.id}"}
          class="mt-3 inline-flex items-center gap-x-1 text-sm font-semibold rounded-lg border border-transparent text-blue-600 hover:text-blue-800 disabled:opacity-50 disabled:pointer-events-none dark:text-blue-500 dark:hover:text-blue-400 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
        >
          Go to app
          <svg
            class="flex-shrink-0 size-4"
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
            <path d="m9 18 6-6-6-6" />
          </svg>
        </.link>
      </section>
    </section>
    """
  end

  def mount(_params, _session, socket) do
    socket
    |> assign(:apps, Apps.list_applications())
    |> wrap_ok()
  end
end
