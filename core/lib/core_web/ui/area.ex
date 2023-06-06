defmodule CoreWeb.UI.Area do
  use Phoenix.Component

  import Phoenix.Component, except: [form: 1]

  attr(:type, :atom, required: true)
  slot(:inner_block, required: true)

  def dynamic(assigns) do
    ~H"""
    <%= if @type === :content do %>
      <.content>
        <%= render_slot(@inner_block) %>
      </.content>
    <% end %>
    <%= if @type === :form do %>
      <.form>
        <%= render_slot(@inner_block) %>
      </.form>
    <% end %>
    <%= if @type === :sheet do %>
      <.sheet>
        <%= render_slot(@inner_block) %>
      </.sheet>
    <% end %>
    <%= if @type === :fullpage do %>
      <.full_page>
        <%= render_slot(@inner_block) %>
      </.full_page>
    <% end %>
    """
  end

  attr(:class, :string, default: "")
  slot(:inner_block, required: true)

  def content(assigns) do
    ~H"""
    <div class={"flex w-full #{@class}"}>
      <div class="flex-grow mx-6 lg:mx-14">
        <div class="w-full">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  attr(:class, :string, default: "")
  slot(:inner_block, required: true)

  def form(assigns) do
    ~H"""
    <div class={"flex justify-center #{@class}"}>
      <div class="flex-grow sm:max-w-form">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:class, :string, default: "")
  slot(:inner_block, required: true)

  def sheet(assigns) do
    ~H"""
    <div class={"flex justify-center #{@class}"}>
      <div class="flex-grow sm:max-w-sheet">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:class, :string, default: "")
  slot(:inner_block, required: true)

  def full_page(assigns) do
    ~H"""
    <div class={@class}>
      <div>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
