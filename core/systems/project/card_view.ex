defmodule Systems.Project.CardView do
  use CoreWeb, :html

  import Frameworks.Pixel.Tag
  alias Frameworks.Pixel.ClickableCard
  alias Frameworks.Pixel.Card

  attr(:card, :map, required: true)
  attr(:click_event_name, :string, default: "handle_click")
  attr(:click_event_data, :map)

  def dynamic(%{card: card} = assigns) do
    assigns =
      assign(assigns, %{
        function:
          case card do
            %{type: :primary} -> &primary/1
            _ -> &secondary/1
          end
      })

    ~H"""
    <div class="h-full">
      <.function_component
        function={@function}
        props={%{
          card: @card,
          click_event_name: @click_event_name,
          click_event_data: @click_event_data
        }}
      />
    </div>
    """
  end

  attr(:card, :any, required: true)
  attr(:click_event_name, :string, default: "handle_click")
  attr(:click_event_data, :map)

  def primary(assigns) do
    ~H"""
    <.basic
      {@card}
      click_event_data={@click_event_data}
      click_event_name={@click_event_name}
    />
    """
  end

  attr(:card, :any, required: true)
  attr(:click_event_name, :string, default: "handle_click")
  attr(:click_event_data, :map)

  def secondary(assigns) do
    ~H"""
    <.basic
      {@card}
      bg_color="grey5"
      text_color="text-grey1"
      label_type="primary"
      tag_type="primary"
      info1_color="text-grey1"
      info2_color="text-grey2"
      click_event_data={@click_event_data}
      click_event_name={@click_event_name}
    />
    """
  end

  attr(:id, :any, required: true)
  attr(:title, :string, required: true)
  attr(:label, :map, required: true)
  attr(:tags, :list, default: [])

  attr(:bg_color, :string, default: "grey1")
  attr(:text_color, :string, default: "text-white")
  attr(:label_type, :string, default: "tertiary")
  attr(:tag_type, :string, default: "grey2")
  attr(:info1_color, :string, default: "text-tertiary")
  attr(:info2_color, :string, default: "text-white")
  attr(:click_event_name, :string, default: "handle_click")
  attr(:click_event_data, :map)
  attr(:left_actions, :list, default: nil)
  attr(:right_actions, :list, default: nil)

  def basic(assigns) do
    ~H"""
    <div class="h-full">
      <.live_component
        module={ClickableCard}
        bg_color={@bg_color}
        id={@id}
        click_event_name={@click_event_name}
        click_event_data={@click_event_data}
        left_actions={@left_actions}
        right_actions={@right_actions}
      >
        <:top>
          <div>
            <.spacing value="S" />
            <Card.label {@label} />
          </div>
        </:top>

        <:title>
          <div class={"text-title5 font-title5 lg:text-title3 lg:font-title3 #{@text_color}"}>
            <%= @title %>
          </div>
        </:title>

        <div class="flex items-center">
          <div class="flex-wrap">
            <%= if @tags do %>
              <div class="flex flex-wrap items-center gap-y-3">
                <%= for tag <- @tags do %>
                  <.tag text={tag} bg_color={"bg-#{@tag_type}"} text_color={"text-#{@tag_type}"} />
                  <.spacing value="XS" direction="l" />
                <% end %>
              </div>
              <.spacing value="S" />
            <% end %>

            <%= if Enum.count(@info) > 0 do %>
              <Text.sub_head color={@info1_color}>
                <%= @info |> List.first() %>
              </Text.sub_head>
            <% end %>

          </div>
          <div class="flex-grow" />
        </div>
      </.live_component>
    </div>
    """
  end
end
