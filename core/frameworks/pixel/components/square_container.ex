defmodule Frameworks.Pixel.Square do
  use CoreWeb, :pixel

  alias Frameworks.Pixel.Icon
  alias Frameworks.Pixel.Button
  alias Frameworks.Pixel.Text

  slot(:inner_block, required: true)

  def container(assigns) do
    ~H"""
    <div class="relative rounded-lg bg-grey6 h-248px">
      <div class="absolute top-0 left-0 w-full flex flex-row gap-6 p-6 overflow-scroll scrollbar-hidden">
        <%= render_slot(@inner_block) %>
      </div>
      <div class="absolute top-0 right-0 h-full w-64px rounded-tr-lg rounded-br-lg bg-gradient-to-r from-white to-black opacity-5" />
    </div>
    """
  end

  def item_style(state) do
    case state do
      :transparent -> "bg-square-border-striped bg-opacity-0"
      :active -> "border-2 border-primary bg-opacity-0"
      {:active, :success} -> "border-2 border-success bg-opacity-0"
      {:active, :warning} -> "border-2 border-warning bg-opacity-0"
      {:active, :error} -> "border-2 border-error bg-opacity-0"
      _ -> "bg-white shadow-2xl"
    end
  end

  def item_subtitle_style(state) do
    case state do
      :active -> "text-primary"
      {:active, :success} -> "text-success"
      {:active, :warning} -> "text-warning"
      {:active, :error} -> "text-error"
      _ -> "text-grey2"
    end
  end

  attr(:icon, :any, default: nil)
  attr(:title, :string, required: true)
  attr(:subtitle, :string, default: nil)
  attr(:state, :any, default: :solid)
  attr(:action, :any, required: true)

  def item(%{state: state} = assigns) do
    style = item_style(state)
    subtitle_style = item_subtitle_style(state)

    assigns =
      assign(assigns, %{
        style: style,
        subtitle_style: subtitle_style
      })

    ~H"""
    <Button.action {@action}>
      <div class={"flex flex-col gap-4 w-200px h-200px px-4 py-5 items-center justify-center rounded-lg cursor-pointer #{@style}"}>
        <%= if @icon do %>
          <Icon.square type={elem(@icon, 0)} src={elem(@icon, 1)} />
        <% end %>
        <Text.title5>
          <%= @title %>
        </Text.title5>
        <%= if @subtitle do %>
          <Text.title5 color={@subtitle_style}>
            <%= @subtitle %>
          </Text.title5>
        <% end %>
      </div>
    </Button.action>
    """
  end
end
