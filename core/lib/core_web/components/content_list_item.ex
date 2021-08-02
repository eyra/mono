defmodule CoreWeb.Components.ContentListItem do
  use Surface.Component
  alias Surface.Components.LiveRedirect
  alias Core.ImageHelpers

  alias EyraUI.{Image, Spacing}
  alias EyraUI.Text.{Label}

  prop(to, :string, required: true)
  prop(title, :string, required: true)
  prop(description, :string, required: true)
  prop(quick_summary, :string, required: true)
  prop(status, :any, required: true)
  prop(image_id, :any, required: true)

  prop(title_css, :css_class,
    default: "font-title7 text-title7 md:font-title5 md:text-title5 text-grey1"
  )

  prop(subtitle_css, :css_class, default: "text-bodysmall md:text-bodymedium font-body text-grey2")

  data(image_info, :any)

  def label_bg_color(%{color: "warning"}), do: "bg-warning"
  def label_bg_color(%{color: "success"}), do: "bg-success"
  def label_text_color(%{color: "warning"}), do: "text-white"
  def label_text_color(%{color: "success"}), do: "text-white"
  def label_text_color(_), do: "text-grey1"

  def render(assigns) do
    assigns =
      assigns
      |> Map.put(:image_info, ImageHelpers.get_image_info(assigns.image_id, 96, 96))

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
                  <div class={{@subtitle_css}}>{{@quick_summary}}</div>
                  <Spacing value="XXS" />
                  <div class="flex flex-row">
                    <div class="flex-wrap">
                      <div class="{{label_bg_color(@status)}} {{label_text_color(@status)}} w-full text-center rounded-full px-2 py-2px font-caption text-captionsmall md:text-caption" >
                        {{@status.label}}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
              <!-- LARGE VARIANT -->
              <div class="hidden lg:block w-full">
                <div class="flex flex-row w-full">
                  <div class="flex-grow">
                    <div class={{@title_css}}>{{@title}}</div>
                    <Spacing value="XXS" />
                    <div class={{@subtitle_css}}>{{@description}}</div>
                  </div>
                  <div class="flex-wrap flex-shrink-0 px-6 place-self-center">
                    <Label color="text-grey2">
                      {{@quick_summary}}
                    </Label>
                  </div>
                  <div class="flex-wrap flex-shrink-0 px-6 place-self-center">
                    <div class="{{label_bg_color(@status)}} {{label_text_color(@status)}} w-full text-center rounded-full px-2 py-3px text-caption font-caption" >
                      {{@status.label}}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="flex-wrap flex-shrink-0 w-20 md:w-24">
              <Image image={{@image_info}} corners="rounded-br-md rounded-tr-xl md:rounded-tr-md" />
            </div>
          </div>
        </div>
      </LiveRedirect>
    """
  end
end
