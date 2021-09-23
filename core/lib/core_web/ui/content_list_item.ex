defmodule CoreWeb.UI.ContentListItem do
  use CoreWeb.UI.Component
  alias Surface.Components.LiveRedirect

  alias EyraUI.{Image}
  alias EyraUI.Text.{Label}

  alias CoreWeb.UI.ContentTag

  defviewmodel(
    path: nil,
    title: nil,
    subtitle: nil,
    quick_summary: nil,
    tag: [type: nil, text: nil],
    image: [type: nil, info: nil],
    title_css: "font-title7 text-title7 md:font-title5 md:text-title5 text-grey1",
    subtitle_css: "text-bodysmall md:text-bodymedium font-body text-grey2"
  )

  prop(vm, :map, required: true)

  data(image_info, :any)

  def render(assigns) do
    ~H"""
      <LiveRedirect to={{path(@vm)}} class="block my-6">
        <div class="font-sans bg-grey5 flex items-stretch space-x-4 rounded-md">
          <div class="flex flex-row w-full">
            <div class="flex-grow p-4 lg:p-6">
              <!-- SMALL VARIANT -->
              <div class="lg:hidden w-full">
                <div>
                  <div class={{title_css(@vm)}}>{{title(@vm)}}</div>
                  <Spacing value="XXS" />
                  <div class={{subtitle_css(@vm)}}>{{subtitle(@vm)}}</div>
                  <Spacing value="XXS" />
                  <div class="flex flex-row">
                    <div class="flex-wrap">
                      <ContentTag vm={{ Map.put(tag(@vm), :size, "S" )}} />
                    </div>
                  </div>
                </div>
              </div>
              <!-- LARGE VARIANT -->
              <div class="hidden lg:block w-full h-full">
                <div class="flex flex-row w-full h-full gap-4 justify-center">
                  <div class="flex-grow">
                    <div class="flex flex-col gap-2 h-full justify-center">
                      <div class={{title_css(@vm)}}>{{title(@vm)}}</div>
                      <div :if={{ has_subtitle?(@vm) }} class={{subtitle_css(@vm)}}>{{subtitle(@vm)}}</div>
                    </div>
                  </div>
                  <div class="flex-shrink-0 w-40 place-self-center">
                    <Label color="text-grey2">
                      {{quick_summary(@vm)}}
                    </Label>
                  </div>
                  <div class="flex-shrink-0 w-30 place-self-center">
                    <ContentTag vm={{ Map.put(tag(@vm), :size, "L" )}} />
                  </div>
                </div>
              </div>
            </div>
            <div class="flex-wrap flex-shrink-0">
              <Image :if={{ image_type(@vm) == :catalog }} image={{image_info(@vm)}} corners="rounded-br-md rounded-tr-xl md:rounded-tr-md w-20 md:w-30" />
              <img :if={{ image_type(@vm) == :avatar }} src={{image_info(@vm)}} class="rounded-full w-20 h-20 my-6 mr-6" alt="" />
            </div>
          </div>
        </div>
      </LiveRedirect>
    """
  end
end
