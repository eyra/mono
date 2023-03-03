defmodule Systems.Budget.WalletListItem do
  use CoreWeb.UI.Component

  import CoreWeb.Gettext

  alias Frameworks.Pixel.Text.Label
  alias CoreWeb.UI.ProgressBar

  defviewmodel(
    title: nil,
    subtitle: nil,
    target_amount: 0,
    earned_amount: 0,
    pending_amount: 0,
    title_css: "font-title7 text-title7 md:font-title5z md:text-title5 text-grey1",
    subtitle_css: "text-bodysmall md:text-bodymedium font-body text-grey2 whitespace-pre-wrap"
  )

  defp togo_amount(vm) do
    target_amount(vm) - (earned_amount(vm) + pending_amount(vm))
  end

  prop(vm, :map, required: true)

  data(image_info, :any)

  def render(assigns) do
    ~F"""
    <div class="font-sans bg-grey5 flex items-stretch space-x-4 rounded-md">
      <div class="flex flex-row w-full">
        <div class="flex-grow p-4 lg:p-6">
          <div class="w-full h-full">
            <div class="flex flex-col sm:flex-row  w-full h-full gap-x-4 gap-y-8 justify-center">
              <div class="flex-wrap md:w-48 lg:w-56">
                <div class="flex flex-col gap-2 h-full justify-center">
                  <div class={title_css(@vm)}>{title(@vm)}</div>
                  <div :if={has_subtitle?(@vm)} class={subtitle_css(@vm)}>{subtitle(@vm)}</div>
                </div>
              </div>
              <div class="flex-grow">
                <ProgressBar
                  bg_color="bg-grey3"
                  size={max(target_amount(@vm), earned_amount(@vm) + pending_amount(@vm))}
                  bars={[
                    %{color: :warning, size: earned_amount(@vm) + pending_amount(@vm)},
                    %{color: :success, size: earned_amount(@vm)}
                  ]}
                />

                <div class="flex flex-row flex-wrap gap-y-4 gap-x-8 mt-6">
                  <div :if={earned_amount(@vm) > 0}>
                    <div class="flex flex-row items-center gap-3">
                      <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-success" />
                      <Label>{earned_amount(@vm)} {dgettext("eyra-assignment", "earned.label")}</Label>
                    </div>
                  </div>
                  <div :if={pending_amount(@vm) > 0}>
                    <div class="flex flex-row items-center gap-3">
                      <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-warning" />
                      <Label>{pending_amount(@vm)} {dgettext("eyra-assignment", "pending.label")}</Label>
                    </div>
                  </div>
                  <div :if={togo_amount(@vm) > 0}>
                    <div class="flex flex-row items-center gap-3">
                      <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-grey3" />
                      <Label>{togo_amount(@vm)} {dgettext("eyra-assignment", "togo.label")}</Label>
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

defmodule Systems.Budget.WalletListItem.Example do
  use Surface.Catalogue.Example,
    subject: Systems.Budget.WalletListItem,
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
      pending_amount: 4
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
