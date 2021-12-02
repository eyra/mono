defmodule Frameworks.Pixel.Card.Campaign do
  @moduledoc """
  A large eye-catcher meant to call a user into taking an action.
  """
  use Surface.Component

  alias Frameworks.Pixel.{Tag, Spacing, Icon}
  alias Frameworks.Pixel.Text.SubHead
  alias Frameworks.Pixel.Card.ClickableCard
  alias Frameworks.Pixel.Image

  prop(conn, :any, required: true)
  prop(path_provider, :any, required: true)
  prop(card, :any, required: true)
  prop(bg_color, :css_class, default: "grey1")
  prop(text_color, :css_class, default: "text-white")
  prop(label_type, :string, default: "tertiary")
  prop(tag_type, :css_class, default: "grey2")
  prop(info1_color, :css_class, default: "text-tertiary")
  prop(info2_color, :css_class, default: "text-white")
  prop(click_event_name, :string)
  prop(click_event_data, :string)

  def left_actions(%{left_actions: left_actions}) when not is_nil(left_actions), do: left_actions
  def left_actions(_), do: []

  def right_actions(%{right_actions: right_actions}) when not is_nil(right_actions), do: right_actions
  def right_actions(_), do: []

  def render(assigns) do
    ~H"""
    <ClickableCard
      bg_color={{@bg_color}}
      id={{@card.id}}
      click_event_name={{@click_event_name}}
      click_event_data={{@click_event_data}}
      left_actions={{left_actions(@card)}}
      right_actions={{right_actions(@card)}}
    >
      <template slot="image">
        <div class="relative">
          <If condition={{ @card.label }} >
            <div class="absolute top-6 z-10">
              <Frameworks.Pixel.Card.Label conn={{@socket}} path_provider={{@path_provider}} text={{@card.label.text}} type={{@card.label.type}} />
            </div>
          </If>
          <If condition={{ @card.icon_url }} >
            <div class="absolute top-6 right-6 z-10">
              <Icon size="S" src={{ @card.icon_url }} />
            </div>
          </If>
        <div class="h-image-card">
          <Image image={{@card.image_info}} transition="duration-500" corners="rounded-t-lg"/>
          </div>
        </div>
      </template>
      <template slot="title">
        <div class="text-title5 font-title5 lg:text-title3 lg:font-title3 {{@text_color}}">
            {{ @card.title }}
        </div>
      </template>
          <div class="flex items-center">
              <div class="flex-wrap">
                <If condition={{ @card.tags }} >
                  <div class="flex flex-wrap items-center gap-y-3">
                    <For each={{ tag <- @card.tags }} >
                      <Tag text={{ tag }} bg_color="bg-{{@tag_type}}" text_color="text-{{@tag_type}}" />
                      <Spacing value="XS" direction="l" />
                    </For>
                  </div>
                  <Spacing value="S" />
                </If>
                <If condition={{ Enum.count(@card.info) > 0 }} >
                  <SubHead color={{@info1_color}}>
                    {{ @card.info |> List.first() }}
                  </SubHead>
                  <Spacing value="M" />
                </If>
                <If condition={{ Enum.count(@card.info) > 1 }} >
                  <SubHead color={{@info2_color}}>
                    {{ @card.info |> Enum.at(1) }}
                  </SubHead>
                </If>
                <If condition={{ Enum.count(@card.info) > 2 }} >
                  <Spacing value="XXS" />
                  <SubHead color={{@info2_color}}>
                    {{ @card.info |> Enum.at(2) }}
                  </SubHead>
                </If>
              </div>
              <div class="flex-grow"></div>
      </div>
    </ClickableCard>
    """
  end
end

defmodule Frameworks.Pixel.Card.Campaign.Example do
  use Surface.Catalogue.Example,
    subject: Frameworks.Pixel.Card.Campaign,
    catalogue: Frameworks.Pixel.Catalogue,
    height: "640px",
    direction: "vertical",
    container: {:div, class: ""}

  alias CoreWeb.Router.Helpers, as: Routes

  def handle_info({:card_click, id}, socket) do
    IO.puts("card_click: campaign ##{id}")
    {:noreply, socket}
  end

  def handle_event(event, %{"item" => item}, socket) do
    IO.puts("#{event}: campaign ##{item}")
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <Campaign conn={{@socket}} path_provider={{Routes}} card={{
      %{
        type: :primary,
        id: 777,
        edit_id: 1,
        open_id: 2,
        title: "Title",
        image_info: Core.ImageHelpers.get_image_info(nil, 400, 300),
        tags: ["Tag1", "Tag2"],
        duration: "10",
        info: ["info1", "info2"],
        icon_url: nil,
        label: %{text: "Label", type: :disabled},
        label_type: "secondary",
        left_actions: [
          %{
            action: %{type: :send, event: "share", item: "777"},
            face: %{
              type: :label,
              label: "Share",
              font: "text-subhead font-subhead",
              text_color: "text-white",
              wrap: true
            }
          },
          %{
            action: %{type: :send, event: "duplicate", item: "777"},
            face: %{
              type: :label,
              label: "Duplicate",
              font: "text-subhead font-subhead",
              text_color: "text-white",
              wrap: true
            }
          }
        ],
        right_actions: [
          %{
            action: %{type: :send, event: "delete", item: ""},
            face: %{type: :icon, icon: :delete, color: :white}
          }
        ]
      }
    }} />
    """
  end
end
