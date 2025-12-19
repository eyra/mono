defmodule Frameworks.Pixel.Button.Action do
  @moduledoc """
  Button action components that handle different interaction types.

  ## Testing Convention
  All action functions must accept an optional `data-testid` attribute that is applied
  to the outermost interactive element (button, anchor, div, etc.). This ensures:
  - Test selectors target the actual clickable element
  - Disabled states still have testids on their wrapper
  - Each action type correctly applies testids to its specific HTML semantics

  When adding new action types, always include:
  ```elixir
  attr(:"data-testid", :string, default: nil)
  ```
  And apply it to the outermost interactive element:
  ```elixir
  <a ... data-testid={assigns[:"data-testid"]}>
  ```
  """
  use CoreWeb, :pixel

  slot(:inner_block, required: true)
  attr(:"data-testid", :string, default: nil)

  def fake(assigns) do
    ~H"""
    <div class="cursor-pointer focus:outline-none" data-testid={assigns[:"data-testid"]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:js, :any, required: true)
  slot(:inner_block, required: true)
  attr(:"data-testid", :string, default: nil)

  def phoenix_js(assigns) do
    ~H"""
    <div phx-click={@js} class="cursor-pointer focus:outline-none" data-testid={assigns[:"data-testid"]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:to, :string, required: true)
  slot(:inner_block, required: true)
  attr(:replace, :boolean, default: false)
  attr(:"data-testid", :string, default: nil)

  def redirect(assigns) do
    ~H"""
    <a
      href={@to}
      class="cursor-pointer focus:outline-none block"
      data-phx-link="redirect"
      data-phx-link-state={if @replace do "replace" else "push" end}
      data-testid={assigns[:"data-testid"]}
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
  attr(:"data-testid", :string, default: nil)

  def send(assigns) do
    ~H"""
    <%= if @enabled? do %>
      <div
        phx-click={@event}
        phx-value-item={@item}
        phx-target={@target}
        class="touchstart-sensitive cursor-pointer focus:outline-none"
        data-testid={assigns[:"data-testid"]}
      >
        <%= render_slot(@inner_block) %>
      </div>
    <% else %>
      <div class="opacity-30" data-testid={assigns[:"data-testid"]}>
        <%= render_slot(@inner_block) %>
      </div>
    <% end %>
    """
  end

  attr(:form_id, :string, default: nil)
  slot(:inner_block, required: true)
  attr(:"data-testid", :string, default: nil)

  def submit(assigns) do
    ~H"""
    <%= if @form_id != nil do %>
      <button
        type="submit"
        class="cursor-pointer focus:outline-none"
        form={@form_id}
        data-testid={assigns[:"data-testid"]}
      >
        <%= render_slot(@inner_block) %>
      </button>
    <% else %>
      <button
        type="submit"
        class="cursor-pointer focus:outline-none"
        data-testid={assigns[:"data-testid"]}
      >
        <%= render_slot(@inner_block) %>
      </button>
    <% end %>
    """
  end

  attr(:field, :string, required: true)
  slot(:inner_block, required: true)
  attr(:"data-testid", :string, default: nil)

  def label(assigns) do
    ~H"""
    <label for={@field} data-testid={assigns[:"data-testid"]}>
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  attr(:id, :string, required: true)
  attr(:target, :string, required: true)
  slot(:inner_block, required: true)
  attr(:"data-testid", :string, default: nil)

  def toggle(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="Toggle"
      target={@target}
      class="cursor-pointer focus:outline-none"
      data-testid={assigns[:"data-testid"]}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:"data-testid", :string, default: nil)
  slot(:inner_block, required: true)

  def sidepanel(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="NativeWrapper"
      class="cursor-pointer"
      data-testid={assigns[:"data-testid"]}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:to, :string, required: true)
  attr(:method, :string, required: true)
  attr(:target, :string, default: "_self")
  slot(:inner_block, required: true)
  attr(:"data-testid", :string, default: nil)

  def http(assigns) do
    ~H"""
    <a
      class="cursor-pointer"
      href={@to}
      data-to={@to}
      data-method={@method}
      data-csrf={Plug.CSRFProtection.get_csrf_token_for(@to)}
      target={@target}
      data-testid={assigns[:"data-testid"]}
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
  attr(:"data-testid", :string, default: nil)

  def http_get(assigns) do
    ~H"""
    <a href={@to} target={@target} phx-target={@phx_target} phx-click={@phx_event} data-testid={assigns[:"data-testid"]}>
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
  attr(:"data-testid", :string, default: nil)

  def http_download(assigns) do
    ~H"""
    <a href={@to} download data-testid={assigns[:"data-testid"]}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end
