defmodule EyraUI.Card.Study do
  @moduledoc """
  A large eye-catcher meant to call a user into taking an action.
  """
  use Surface.Component

  alias EyraUI.{Tag, Spacing, Icon}
  alias EyraUI.Text.{SubHead, Label}
  alias EyraUI.Card.Card
  alias EyraUI.Image

  prop(conn, :any, required: true)
  prop(path_provider, :any, required: true)
  prop(card, :any, required: true)
  prop(bg_color, :css_class, default: "bg-grey1")
  prop(text_color, :css_class, default: "text-white")
  prop(label_type, :string, default: "tertiary")
  prop(tag_type, :css_class, default: "grey2")
  prop(info1_color, :css_class, default: "text-tertiary")
  prop(info2_color, :css_class, default: "text-white")
  prop(click_event_name, :string)
  prop(click_event_data, :string)

  def render(assigns) do
    ~H"""
    <Card bg_color={{@bg_color}} id={{@card.id}} click_event_name={{@click_event_name}} click_event_data={{@click_event_data}}>
      <template slot="image">
        <div class="relative">
          <If condition={{ @card.label }} >
            <div class="absolute top-6">
              <EyraUI.Card.Label conn={{@socket}} path_provider={{@path_provider}} text={{@card.label}} type={{@label_type}} />
            </div>
          </If>
          <If condition={{ @card.icon_url }} >
            <div class="absolute top-6 right-6 z-20">
              <Icon size="S" src={{ @card.icon_url }} />
            </div>
          </If>
        <div class="h-image-card" x-data="blurHash()">
          <Image id={{@card.id}} image={{@card.image_info}} class="rounded-t-lg bg-grey4 object-cover w-full h-full" />
          </div>
        </div>
      </template>
      <template slot="title">
        <div class="text-title5 font-title5 lg:text-title3 lg:font-title3 {{@text_color}}">
            {{ @card.title }}
        </div>
      </template>
      <div class="mt-6 lg:mt-8">
          <div class="flex items-center">
              <div class="flex-wrap">
                <If condition={{ @card.tags }} >
                  <div class="flex items-center">
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
                  <Label color={{@info2_color}}>
                    {{ @card.info |> Enum.at(1) }}
                  </Label>
                </If>
                <If condition={{ Enum.count(@card.info) > 2 }} >
                  <Spacing value="2" />
                  <Label color={{@info2_color}}>
                    {{ @card.info |> Enum.at(2) }}
                  </Label>
                </If>
              </div>
              <div class="flex-grow"></div>
          </div>
      </div>
    </Card>
    """
  end
end
