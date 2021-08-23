defmodule CoreWeb.UI.ContentListItem do
  use CoreWeb.UI.Component
  alias Surface.Components.LiveRedirect
  alias Core.ImageHelpers

  alias EyraUI.{Image}
  alias EyraUI.Text.{Label}

  prop(to, :string, required: true)
  prop(title, :string, required: true)
  prop(subtitle, :string, required: true)
  prop(quick_summary, :string, required: true)
  prop(label, :map, required: true)
  prop(image_id, :any, required: true)

  prop(title_css, :css_class,
    default: "font-title7 text-title7 md:font-title5 md:text-title5 text-grey1"
  )

  prop(subtitle_css, :css_class, default: "text-bodysmall md:text-bodymedium font-body text-grey2")

  data(image_info, :any)

  def label_bg_color(%{type: type}), do: "bg-#{type}"

  def label_text_color(%{type: :tertiary}), do: "text-grey1"
  def label_text_color(_), do: "text-white"

  def render(assigns) do
    assigns =
      assigns
      |> Map.put(:image_info, ImageHelpers.get_image_info(assigns.image_id, 120, 115))

    ~H"""
      <LiveRedirect to={{@to}} class="block my-6">
        <div class="font-sans bg-grey5 flex items-stretch space-x-4 rounded-md">
          <div class="flex flex-row w-full">
            <div class="flex-grow p-4 lg:p-6">
              <!-- SMALL VARIANT -->
              <div class="lg:hidden w-full">
                <div>
                  <div class={{@title_css}}>{{@title}}</div>
                  <Spacing value="XXS" />
                  <div class={{@subtitle_css}}>{{@subtitle}}</div>
                  <Spacing value="XXS" />
                  <div class="flex flex-row">
                    <div class="flex-wrap">
                      <div class="{{label_bg_color(@label)}} {{label_text_color(@label)}} w-full text-center rounded-full px-2 py-2px font-caption text-captionsmall md:text-caption" >
                        {{@label.text}}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <!-- LARGE VARIANT -->
              <div class="hidden lg:block w-full h-full">
                <div class="flex flex-row w-full h-full gap-4 justify-center">
                  <div class="flex-grow">
                    <div class="flex flex-col gap-2 h-full justify-center">
                      <div class={{@title_css}}>{{@title}}</div>
                      <div :if={{ @subtitle != nil && @subtitle != "" }} class={{@subtitle_css}}>{{@subtitle}}</div>
                    </div>
                  </div>
                  <div class="flex-shrink-0 w-30 place-self-center">
                    <Label color="text-grey2">
                      {{@quick_summary}}
                    </Label>
                  </div>
                  <div class="flex-shrink-0 w-30 place-self-center">
                    <div class="flex flex-row justify-center w-full">
                      <div class="{{label_bg_color(@label)}} {{label_text_color(@label)}} flex-wraptext-center rounded-full px-2 py-3px text-caption font-caption" >
                        {{@label.text}}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="flex-wrap flex-shrink-0 w-20 md:w-30">
              <Image image={{@image_info}} corners="rounded-br-md rounded-tr-xl md:rounded-tr-md" />
            </div>
          </div>
        </div>
      </LiveRedirect>
    """
  end
end
