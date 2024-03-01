defmodule MakinaWeb.ServiceComponents do
  use Phoenix.Component
  use MakinaWeb, :verified_routes

  import MakinaWeb.CoreComponents

  alias Phoenix.LiveView.JS

  attr :form, :map, required: true

  def environment_form(assigns) do
    ~H"""
    <.inputs_for :let={f_env} field={@form}>
      <input type="hidden" class="hidden" name="service[envs_sort][]" value={f_env.index} />
      <div class="flex space-x-2">
        <.input type="text" field={f_env[:name]} placeholder="name" />
        <.input type="text" field={f_env[:value]} placeholder="value" />
        <button
          name="service[envs_drop][]"
          type="button"
          class="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent text-gray-500 hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none dark:text-gray-400 dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
          value={f_env.index}
          phx-click={JS.dispatch("change")}
        >
          <.icon name="hero-minus" />
        </button>
      </div>
    </.inputs_for>

    <input type="hidden" name="service[envs_drop][]" />
    <button
      type="button"
      class="w-max py-3 px-4 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-900 dark:border-gray-700 dark:text-white dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
      name="service[envs_sort][]"
      value="new"
      phx-click={JS.dispatch("change")}
    >
      <.icon name="hero-plus" />
    </button>
    """
  end

  attr :form, :map, required: true

  def volumes_form(assigns) do
    ~H"""
    <.inputs_for :let={f_env} field={@form}>
      <input type="hidden" class="hidden" name="service[volumes_sort][]" value={f_env.index} />
      <div class="flex space-x-2">
        <.input type="text" field={f_env[:name]} placeholder="name" />
        <.input type="text" field={f_env[:mount_point]} placeholder="mount point" />
        <button
          name="service[volumes_drop][]"
          type="button"
          class="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent text-gray-500 hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none dark:text-gray-400 dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
          value={f_env.index}
          phx-click={JS.dispatch("change")}
        >
          <.icon name="hero-minus" />
        </button>
      </div>
    </.inputs_for>

    <input type="hidden" name="service[volumes_drop][]" />

    <button
      type="button"
      class="w-max py-3 px-4 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-900 dark:border-gray-700 dark:text-white dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
      name="service[volumes_sort][]"
      value="new"
      phx-click={JS.dispatch("change")}
    >
      <.icon name="hero-plus" />
    </button>
    """
  end

  attr :form, :map, required: true

  def domains_form(assigns) do
    ~H"""
    <.inputs_for :let={f_env} field={@form}>
      <input type="hidden" class="hidden" name="service[domains_sort][]" value={f_env.index} />
      <div class="flex space-x-2">
        <.input type="text" field={f_env[:domain]} placeholder="domain" />
        <button
          name="service[domains_drop][]"
          type="button"
          class="py-3 px-4 inline-flex items-center gap-x-2 text-sm font-semibold rounded-lg border border-transparent text-gray-500 hover:bg-gray-100 disabled:opacity-50 disabled:pointer-events-none dark:text-gray-400 dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
          value={f_env.index}
          phx-click={JS.dispatch("change")}
        >
          <.icon name="hero-minus" />
        </button>
      </div>
    </.inputs_for>

    <input type="hidden" name="service[domains_drop][]" />
    <button
      type="button"
      class="w-max py-3 px-4 inline-flex items-center gap-x-2 text-sm font-medium rounded-lg border border-gray-200 bg-white text-gray-800 shadow-sm hover:bg-gray-50 disabled:opacity-50 disabled:pointer-events-none dark:bg-slate-900 dark:border-gray-700 dark:text-white dark:hover:bg-gray-800 dark:focus:outline-none dark:focus:ring-1 dark:focus:ring-gray-600"
      name="service[domains_sort][]"
      value="new"
      phx-click={JS.dispatch("change")}
    >
      <.icon name="hero-plus" />
    </button>
    """
  end
end
