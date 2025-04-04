defmodule Systems.Project.CardView do
  use CoreWeb, :html

  import Frameworks.Pixel.Tag
  import Frameworks.Pixel.ClickableCard
  alias Frameworks.Pixel.Card
  alias Frameworks.Pixel.Image

  attr(:card, :map, required: true)

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
      label_type="primary"
      tag_type="primary"
      info1_color="text-grey1"
      info2_color="text-grey2"
    />
    """
  end

  attr(:id, :any, required: true)
  attr(:title, :string, required: true)
  attr(:label, :map, required: true)
  attr(:tags, :list, default: [])
  attr(:image_info, :map, default: nil)
  attr(:icon_url, :string, default: nil)

  attr(:bg_color, :string, default: "grey1")
  attr(:text_color, :string, default: "text-white")
  attr(:label_type, :string, default: "tertiary")
  attr(:tag_type, :string, default: "grey2")
  attr(:info1_color, :string, default: "text-tertiary")
  attr(:info2_color, :string, default: "text-white")
  attr(:left_actions, :list, default: nil)
  attr(:right_actions, :list, default: nil)

  def basic(assigns) do
    ~H"""
    <div class="h-full">
      <.clickable_card
        bg_color={@bg_color}
        id={@id}
        left_actions={@left_actions}
        right_actions={@right_actions}
      >
        <:top>
          <div class="relative">
            <%= if @label do %>
              <div class={"#{if @image_info do "absolute top-6 z-[12]" else "mt-6" end}"}>
                <Card.label {@label} />
              </div>
            <% end %>

            <%= if @icon_url do %>
              <div class="absolute top-6 right-6 z-[12]">
                <Icon.card url={@icon_url} />
              </div>
            <% end %>

            <%= if @image_info do %>
              <div class="h-image-card">
                <Image.blurhash
                  id={Integer.to_string(@id)}
                  image={@image_info}
                />
              </div>
            <% end %>
          </div>
        </:top>

        <:title>
          <div class={"text-title5 font-title5 lg:text-title3 lg:font-title3 truncate #{@text_color}"}>
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
                <span class="whitespace-pre-wrap"><%= @info |> List.first() %></span>
              </Text.sub_head>
            <% end %>

          </div>
          <div class="flex-grow" />
        </div>
      </.clickable_card>
    </div>
    """
  end
end
