defmodule Frameworks.Pixel.Button.Action do
  use CoreWeb, :html

  attr(:code, :string, required: true)
  slot(:inner_block, required: true)

  def click(assigns) do
    ~H"""
    <div x-on:click={@code} class="cursor-pointer focus:outline-none">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:to, :string, required: true)
  slot(:inner_block, required: true)
  attr(:replace, :boolean, default: false)

  def redirect(assigns) do
    ~H"""
    <a
      href={@to}
      class="cursor-pointer focus:outline-none block"
      data-phx-link="redirect"
      data-phx-link-state={if @replace do "replace" else "push" end}
      >
        <%= render_slot(@inner_block) %>
    </a>
    """
  end

  attr(:event, :string, required: true)
  attr(:item, :string, default: "")
  attr(:target, :string, default: "")
  slot(:inner_block, required: true)

  def send(assigns) do
    ~H"""
    <div
      phx-target={@target}
      phx-click={@event}
      phx-value-item={@item}
      class="cursor-pointer focus:outline-none"
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:form_id, :string, default: nil)
  slot(:inner_block, required: true)

  def submit(assigns) do
    ~H"""
    <%= if @form_id != nil do %>
      <button
        type="submit"
        class="cursor-pointer focus:outline-none"
        form={@form_id}
      >
        <%= render_slot(@inner_block) %>
      </button>
    <% else %>
      <button
        type="submit"
        class="cursor-pointer focus:outline-none"
      >
        <%= render_slot(@inner_block) %>
      </button>
    <% end %>
    """
  end

  attr(:id, :string, required: true)
  attr(:target, :string, required: true)
  slot(:inner_block, required: true)

  def toggle(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="Toggle"
      target={@target}
      class="cursor-pointer focus:outline-none"
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def sidepanel(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="NativeWrapper"
      @click={"nativeWrapperHook.toggleSidePanel(); $parent.overlay = true"}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:to, :string, required: true)
  attr(:method, :string, required: true)
  attr(:target, :string, default: "_self")
  slot(:inner_block, required: true)

  def http(assigns) do
    ~H"""
    <a
      class="cursor-pointer"
      href={@to}
      data-to={@to}
      data-method={@method}
      data-csrf={Plug.CSRFProtection.get_csrf_token_for(@to)}
      target={@target}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  attr(:to, :string, required: true)
  attr(:target, :string, default: "_self")
  slot(:inner_block, required: true)

  def http_get(assigns) do
    ~H"""
    <a href={@to} target={@target}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  attr(:to, :string, required: true)
  attr(:target, :string)
  slot(:inner_block, required: true)

  def http_delete(assigns), do: http(assign(assigns, :method, "delete"))

  attr(:to, :string, required: true)
  attr(:target, :string)
  slot(:inner_block, required: true)

  def http_post(assigns), do: http(assign(assigns, :method, "post"))

  attr(:to, :string, required: true)
  attr(:target, :string)
  slot(:inner_block, required: true)

  def http_new(assigns), do: http(assign(assigns, :method, "new"))
end
