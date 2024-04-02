defmodule Systems.Campaign.CardView do
  @moduledoc """
  A large eye-catcher meant to call a user into taking an action.
  """
  use CoreWeb, :html

  alias Frameworks.Pixel.Image
  alias Frameworks.Pixel.Icon

  import Frameworks.Pixel.Tag
  alias Frameworks.Pixel.Card
  import Frameworks.Pixel.ClickableCard

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
        props={%{card: @card}}
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
  attr(:icon_url, :string, required: true)
  attr(:image_info, :map, required: true)
  attr(:title, :string, required: true)
  attr(:tags, :list, default: nil)
  attr(:label, :map, default: nil)
  # FIXME: info lists with more than one item do not get displayed properly (?)
  attr(:info, :list, default: [])

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
              <div class="absolute top-6 z-10">
                <Card.label {@label} />
              </div>
            <% end %>

            <%= if @icon_url do %>
              <div class="absolute top-6 right-6 z-10">
                <Icon.card url={@icon_url} />
              </div>
            <% end %>

            <div class="h-image-card">
              <Image.blurhash
                id={Integer.to_string(@id)}
                image={@image_info}
                transition="duration-500"
                corners="rounded-t-lg"
              />
            </div>
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
              <.spacing value="M" />
            <% end %>

            <%= if Enum.count(@info) > 1 do %>
              <Text.sub_head color={@info2_color}>
                <%= @info |> Enum.at(1) %>
              </Text.sub_head>
            <% end %>

            <%= if Enum.count(@info) > 2 do %>
              <.spacing value="XXS" />
              <Text.sub_head color={@info2_color}>
                <%= @info |> Enum.at(2) %>
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
