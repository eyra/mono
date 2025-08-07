defmodule Frameworks.Builder.HTML do
  use CoreWeb, :html

  alias Frameworks.Pixel.Panel
  alias Frameworks.Pixel.Align

  import CoreWeb.UI.StepIndicator
  import Frameworks.Pixel.Tag

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:items, :list, required: true)

  def library(assigns) do
    ~H"""
    <div class="w-full h-full bg-grey5">
      <Text.title2><%= @title %></Text.title2>
      <Text.body><%= @description %></Text.body>
      <.spacing value="M" />
      <div class="flex flex-col gap-4">
        <%= for item <- @items do %>
          <.library_item {item} />
        <% end %>
      </div>
    </div>
    """
  end

  attr(:type, :any, required: true)
  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:tags, :list, default: nil)

  def library_item(assigns) do
    ~H"""
    <div class="w-full h-full">
      <Panel.flat bg_color="bg-white">
        <Text.title4><%= @title %></Text.title4>
        <.spacing value="XS" />
        <Text.body><%= @description %></Text.body>
        <div :if={@tags}>
          <.spacing value="XS" />
          <div class="flex flex-row gap-2">
            <%= for tag <- @tags do %>
              <.tag text={tag} />
            <% end %>
          </div>
        </div>
        <.spacing value="M" />
        <.wrap>
          <Button.dynamic
            face={%{type: :primary, bg_color: "bg-success", label: dgettext("eyra-workflow", "add.to.button") }}
            action={%{type: :send, event: "add", item: @id}}
          />
        </.wrap>
      </Panel.flat>
    </div>
    """
  end

  attr(:id, :any, required: true)
  attr(:title, :map, required: true)
  attr(:description, :map, default: nil)
  attr(:icon, :string, required: true)
  attr(:status, :atom, default: :pending)
  attr(:index, :integer, required: true)
  attr(:selected?, :boolean, default: true)
  attr(:event, :string, default: "work_item_selected")
  attr(:target, :any, default: "")

  def work_list_item(assigns) do
    ~H"""
    <div
      class={"touchstart-sensitive w-full rounded-lg cursor-pointer p-4 border #{if @selected? do "bg-grey6 border-grey4" else "hover:bg-grey6 border-white" end} "}
      phx-click={@event}
      phx-value-item={@id}
      phx-target={@target}
    >
      <div class="w-full h-full">
        <Align.vertical_center>
          <div class="flex flex-row gap-6 items-start">
            <%= if @status == :pending do %>
              <div class="flex-shrink-0">
                <.step_indicator bg_color="bg-primary" text={@index+1} />
              </div>
            <% else %>
              <div class="h-6 w-6 flex-shrink-0">
                <img class="h-6 w-6" src={~p"/images/icons/ready.svg"} alt="ready">
              </div>
            <% end %>
            <div class="flex-grow">
              <div class="flex flex-col gap-2 pt-[2px]">
                <Text.title6 margin="mb-0" align="text-left"><%= @title %></Text.title6>
                <%= if @description != nil and @status == :pending do %>
                  <div class="font-body text-bodysmall"><%= @description %></div>
                <% end %>
              </div>
            </div>
            <%= if @icon do %>
              <div class="w-8 h-8 flex-shrink-0">
                <img src={~p"/images/icons/#{"#{String.downcase(@icon)}.svg"}"} onerror="this.src='/images/icons/placeholder.svg';" alt={@icon}>
              </div>
            <% end %>
          </div>
        </Align.vertical_center>
      </div>
    </div>
    """
  end

  attr(:title, :string, default: nil)
  slot(:inner_block)

  def collapsed(assigns) do
    ~H"""
    <div>

      <%= if @title do %>
        <Text.title6><%= @title %></Text.title6>
        <.spacing value="M" />
      <% end %>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
