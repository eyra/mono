defmodule CoreWeb.UI.WalletListItem do
  use CoreWeb.UI.Component

  alias Frameworks.Pixel.Text.Label
  alias CoreWeb.UI.ProgressBar

  defviewmodel(
    title: nil,
    subtitle: nil,
    target: 0,
    earned_amount: 0,
    expected_amount: 0,
    title_css: "font-title7 text-title7 md:font-title5 md:text-title5 text-grey1",
    subtitle_css: "text-bodysmall md:text-bodymedium font-body text-grey2 whitespace-pre-wrap"
  )

  prop(vm, :map, required: true)

  data(image_info, :any)

  def render(assigns) do
    ~F"""
      <div class="font-sans bg-grey5 flex items-stretch space-x-4 rounded-md">
        <div class="flex flex-row w-full">
          <div class="flex-grow p-4 lg:p-6">
            <div class="w-full h-full">
              <div class="flex flex-col sm:flex-row  w-full h-full gap-x-4 gap-y-8 justify-center">
                <div class="flex-grow">
                  <div class="flex flex-col gap-2 h-full justify-center">
                    <div class={title_css(@vm)}>{title(@vm)}</div>
                    <div :if={has_subtitle?(@vm)} class={subtitle_css(@vm)}>{subtitle(@vm)}</div>
                  </div>
                </div>
                <div class="flex-grow">
                  <ProgressBar
                    bg_color={"bg-grey3"}
                    size={max(target(@vm), earned_amount(@vm) + expected_amount(@vm))}
                    bars={[
                      %{ color: :warning, size: earned_amount(@vm) + expected_amount(@vm)},
                      %{ color: :success, size: earned_amount(@vm)}
                    ]} />

                  <div class="flex flex-row flex-wrap gap-y-4 gap-x-8 mt-6">
                    <div>
                      <div class="flex flex-row items-center gap-3">
                        <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-success"></div>
                        <Label>{earned_amount(@vm)} earned</Label>
                      </div>
                    </div>
                    <div>
                      <div class="flex flex-row items-center gap-3">
                        <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-warning"></div>
                        <Label>{expected_amount(@vm)} expected</Label>
                      </div>
                    </div>
                    <div>
                      <div class="flex flex-row items-center gap-3">
                        <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-grey3"></div>
                        <Label>{target(@vm) - (earned_amount(@vm) + expected_amount(@vm))} to go</Label>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    """
  end
end

defmodule CoreWeb.UI.WalletListItem.Example do
  use Surface.Catalogue.Example,
    subject: CoreWeb.UI.WalletListItem,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Share view",
    height: "812px",
    direction: "vertical",
    container: {:div, class: ""}

  data(vm1, :map,
    default: %{
      title: Faker.Lorem.sentence(3),
      subtitle: Faker.Lorem.sentence(6),
      earned_amount: 30,
      expected_amount: 4
    }
  )

  def render(assigns) do
    ~F"""
    <div class="flex flex-col gap-10">
      <WalletListItem vm={@vm1} />
    </div>
    """
  end
end
