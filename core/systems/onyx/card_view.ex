defmodule Systems.Onyx.CardView do
  use CoreWeb, :html

  import Frameworks.Pixel.Tag
  import Frameworks.Pixel.ClickableCard

  attr(:card, :map, required: true)

  def dynamic(%{card: card} = assigns) do
    assigns =
      assign(assigns, %{
        function:
          case card do
            %{type: :primary} -> &primary/1
            %{type: :secondary} -> &secondary/1
            %{type: :tertiary} -> &tertiary/1
          end
      })

    ~H"""
    <div class="h-full">
      <.function_component
        function={@function}
        props={%{
          card: @card
        }}
      />
    </div>
    """
  end

  attr(:card, :any, required: true)

  def primary(assigns) do
    ~H"""
    <.basic {@card} />
    """
  end

  attr(:card, :any, required: true)

  def secondary(assigns) do
    ~H"""
    <.basic
      {@card}

      bg_color="grey5"
      text_color="text-grey1"
      tag_type="primary"
      info_color="text-grey1"
    />
    """
  end

  def tertiary(assigns) do
    ~H"""
    <.basic

      {@card}
      bg_color="grey5"
      text_color="text-grey1"
      tag_type="primary"
      info_color="text-grey1"
      title_style="text-title7 font-title7 lg:text-title5 lg:font-title5"
      info_visible={false}
      flex_direction="flex-row"
      tag_limit={1}
    />
    """
  end

  attr(:id, :any, required: true)
  attr(:title, :string, required: true)
  attr(:tags, :list, default: [])
  attr(:info, :list, default: [])
  attr(:info_visible, :boolean, default: true)

  attr(:tag_limit, :integer, default: 3)
  attr(:flex_direction, :string, default: "flex-col")
  attr(:bg_color, :string, default: "primary")
  attr(:text_color, :string, default: "text-white")
  attr(:tag_type, :string, default: "grey2")
  attr(:info_color, :string, default: "text-white")
  attr(:title_style, :string, default: "text-title5 font-title5 lg:text-title3 lg:font-title3")

  def basic(assigns) do
    ~H"""
    <div class="h-full">
      <.clickable_card
        bg_color={@bg_color}
        id={@id}
      >
        <div class={"flex #{@flex_direction} items-left gap-6 w-full h-full"}>
          <div class="flex flex-row gap-x-3 w-full">
            <div class={"#{@title_style} #{@text_color}"}>
              <%= @title %>
            </div>
            <div class="flex-grow" />
            <%= if Enum.count(@tags) > 0 && @tag_limit == 1 do %>
              <div class="flex-wrap">
                <.tag text={List.first(@tags)} bg_color={"bg-#{@tag_type}"} text_color={"text-#{@tag_type}"} />
              </div>
            <% end %>
          </div>
          <%= if Enum.count(@tags) > 0 && @tag_limit > 1 do %>
            <div class={"flex flex-row gap-x-3"}>
              <%= for tag <- @tags |> Enum.take(@tag_limit) do %>
                <.tag text={tag} bg_color={"bg-#{@tag_type}"} text_color={"text-#{@tag_type}"} />
              <% end %>
            </div>
          <% end %>
          <%= if @info_visible && @info do %>
            <Text.sub_head color={@info_color}>
              <span class="whitespace-pre-wrap"><%= @info %></span>
            </Text.sub_head>
          <% end %>
        </div>
      </.clickable_card>
    </div>
    """
  end
end
