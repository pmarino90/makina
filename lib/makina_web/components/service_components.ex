defmodule MakinaWeb.ServiceComponents do
  use Phoenix.Component
  use MakinaWeb, :verified_routes

  import MakinaWeb.CoreComponents, except: [button: 1]
  import ArticUI.Component.Button

  alias Phoenix.LiveView.JS

  attr :form, :map, required: true

  def environment_form(assigns) do
    ~H"""
    <.inputs_for :let={f_env} field={@form}>
      <input type="hidden" class="hidden" name="service[envs_sort][]" value={f_env.index} />
      <div class="flex space-x-2 items-end">
        <.input type="text" field={f_env[:name]} placeholder="name" />
        <.input type="select" field={f_env[:type]} options={["Plain Text": :plain, Secret: :secret]} />
        <.input type="text" field={f_env[:value]} placeholder="value" />
        <.button
          variant="secondary"
          name="service[envs_drop][]"
          value={f_env.index}
          phx-click={JS.dispatch("change")}
        >
          <.icon name="hero-minus" />
        </.button>
      </div>
    </.inputs_for>

    <input type="hidden" name="service[envs_drop][]" />
    <.button
      variant="secondary"
      name="service[envs_sort][]"
      value="new"
      phx-click={JS.dispatch("change")}
    >
      <.icon name="hero-plus" />
    </.button>
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
        <.button
          variant="secondary"
          name="service[volumes_drop][]"
          value={f_env.index}
          phx-click={JS.dispatch("change")}
        >
          <.icon name="hero-minus" />
        </.button>
      </div>
    </.inputs_for>

    <input type="hidden" name="service[volumes_drop][]" />

    <.button
      variant="secondary"
      name="service[volumes_sort][]"
      value="new"
      phx-click={JS.dispatch("change")}
    >
      <.icon name="hero-plus" />
    </.button>
    """
  end

  attr :form, :map, required: true

  def domains_form(assigns) do
    ~H"""
    <.inputs_for :let={f_env} field={@form}>
      <input type="hidden" class="hidden" name="service[domains_sort][]" value={f_env.index} />
      <div class="flex space-x-2">
        <.input type="text" field={f_env[:domain]} placeholder="domain" />
        <.button
          variant="secondary"
          name="service[domains_drop][]"
          value={f_env.index}
          phx-click={JS.dispatch("change")}
        >
          <.icon name="hero-minus" />
        </.button>
      </div>
    </.inputs_for>

    <input type="hidden" name="service[domains_drop][]" />
    <.button
      variant="secondary"
      type="button"
      name="service[domains_sort][]"
      value="new"
      phx-click={JS.dispatch("change")}
    >
      <.icon name="hero-plus" />
    </.button>
    """
  end

  attr :section, :atom, required: true
  attr :edit_mode, :atom

  def section_edit_actions(assigns) do
    ~H"""
    <.button
      :if={@edit_mode != @section}
      type="button"
      variant="secondary"
      value={Atom.to_string(@section)}
      disabled={not is_nil(@edit_mode)}
      phx-click="set_edit_mode"
      phx-disable-with="loading..."
    >
      Edit
    </.button>

    <.button
      :if={@edit_mode == @section}
      data-controller="hotkey"
      data-hotkey="Escape"
      type="button"
      variant="secondary"
      phx-click="cancel_edit"
    >
      Cancel
    </.button>

    <.button
      :if={@edit_mode == @section}
      type="button"
      value="domains"
      phx-click={JS.dispatch("submit", to: "##{@section}-update-form")}
      phx-disable-with="Saving..."
    >
      Save
    </.button>
    """
  end

  def display_env_var_value(var) do
    case var.type do
      :plain -> var.text_value
      :secret -> "*********"
    end
  end
end
