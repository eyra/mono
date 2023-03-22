defmodule Systems.Budget.BalanceView do
  use CoreWeb.UI.Component

  alias CoreWeb.UI.ProgressBar
  alias Frameworks.Pixel.Text.Label

  prop(progress, :map, required: true)
  prop(available, :string, required: true)
  prop(reserved, :string, required: true)
  prop(spend, :string, required: true)

  def render(assigns) do
    ~F"""
    <div class="bg-grey6 rounded p-12">
      <ProgressBar {...@progress} />
      <div class="flex flex-row flex-wrap gap-y-4 gap-x-12 mt-12">
        <div>
          <div class="flex flex-row items-center gap-3">
            <div class="flex-shrink-0 w-6 h-6 rounded-full bg-success" />
            <Label>{@available} {dgettext("eyra-budget", "budget.available.label")}</Label>
          </div>
        </div>
        <div>
          <div class="flex flex-row items-center gap-3">
            <div class="flex-shrink-0 w-6 h-6 rounded-full bg-warning" />
            <Label>{@reserved} {dgettext("eyra-budget", "budget.reserved.label")}</Label>
          </div>
        </div>
        <div>
          <div class="flex flex-row items-center gap-3">
            <div class="flex-shrink-0 w-6 h-6 rounded-full bg-grey4" />
            <Label>{@spend} {dgettext("eyra-budget", "budget.spend.label")}</Label>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
