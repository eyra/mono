defmodule Frameworks.Pixel.Button.Action do
  use CoreWeb, :pixel

  slot(:inner_block, required: true)

  def fake(assigns) do
    ~H"""
    <div class="cursor-pointer focus:outline-none">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

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

  attr(:id, :string, default: "?")
  attr(:event, :string, required: true)
  attr(:item, :string, default: "")
  attr(:target, :string, default: "")
  attr(:enabled?, :boolean, default: true)
  slot(:inner_block, required: true)

  def send(assigns) do
    ~H"""
    <%= if @enabled? do %>
      <div
        phx-click={@event}
        phx-value-item={@item}
        phx-target={@target}
        class="touchstart-sensitive cursor-pointer focus:outline-none"
      >
        <%= render_slot(@inner_block) %>
      </div>
    <% else %>
      <div class="opacity-30">
        <%= render_slot(@inner_block) %>
      </div>
    <% end %>
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

  attr(:field, :string, required: true)
  slot(:inner_block, required: true)

  def label(assigns) do
    ~H"""
    <label for={@field}>
      <%= render_slot(@inner_block) %>
    </label>
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
  attr(:phx_event, :string, default: nil)
  attr(:phx_target, :string, default: nil)
  slot(:inner_block, required: true)

  def http_get(assigns) do
    ~H"""
    <a href={@to} target={@target} phx-target={@phx_target} phx-click={@phx_event}>
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

  attr(:to, :string, required: true)
  slot(:inner_block, required: true)

  def http_download(assigns) do
    ~H"""
    <a href={@to} download>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end
