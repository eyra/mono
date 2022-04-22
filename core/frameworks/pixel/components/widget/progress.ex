defmodule Frameworks.Pixel.Widget.Progress do
  use Frameworks.Pixel.Component

  import CoreWeb.Gettext

  alias Frameworks.Pixel.Text.{Label, Title5}

  alias CoreWeb.UI.ProgressBar

  prop(label, :string, required: true)
  prop(target_amount, :integer, required: true)
  prop(earned_amount, :integer, required: true)
  prop(pending_amount, :integer, required: true)

  defp togo_amount(%{
         target_amount: target_amount,
         earned_amount: earned_amount,
         pending_amount: pending_amount
       }) do
    target_amount - (earned_amount + pending_amount)
  end

  def render(assigns) do
    ~F"""
    <div class="rounded-lg shadow-2xl p-6 h-full">
      <Title5>{@label}</Title5>
      <div class="mt-6" />
      <ProgressBar
        bg_color={"bg-grey3"}
        size={max(@target_amount, @earned_amount + @pending_amount)}
        bars={[
          %{ color: :warning, size: @earned_amount + @pending_amount},
          %{ color: :success, size: @earned_amount}
        ]} />

      <div class="flex flex-row flex-wrap items-center gap-y-4 gap-x-8 mt-6">
        <div :if={@earned_amount > 0}>
          <div class="flex flex-row items-center gap-3">
            <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-success"></div>
            <Label>{@earned_amount} {dgettext("eyra-assignment", "earned.label")}</Label>
          </div>
        </div>
        <div :if={@pending_amount > 0}>
          <div class="flex flex-row items-center gap-3">
            <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-warning"></div>
            <Label>{@pending_amount} {dgettext("eyra-assignment", "pending.label")}</Label>
          </div>
        </div>
        <div :if={togo_amount(assigns) > 0}>
          <div class="flex flex-row items-center gap-3">
            <div class="flex-shrink-0 w-6 h-6 -mt-2px rounded-full bg-grey3"></div>
            <Label>{togo_amount(assigns)} {dgettext("eyra-assignment", "togo.label")}</Label>
          </div>
        </div>
      </div>
    </div>
    """
  end
end

defmodule Framworks.Pixel.Widget.Progress.Example do
  use Surface.Catalogue.Example,
    subject: Frameworks.Pixel.Widget.Progress,
    catalogue: Frameworks.Pixel.Catalogue,
    height: "1024px",
    direction: "vertical",
    container: {:div, class: ""}

  def render(assigns) do
    ~F"""
      <div class="flex flex-col gap-8 h-full">
        <Progress label="Total issued credits" target_amount={60} earned_amount={30} pending_amount={7} />
        <Progress label="Progress bar" target_amount={60} earned_amount={60} pending_amount={7} />
        <Progress label="Progress bar" target_amount={60} earned_amount={60} pending_amount={0} />
        <Progress label="Progress bar" target_amount={60} earned_amount={0} pending_amount={7} />
        <Progress label="Progress bar" target_amount={60} earned_amount={0} pending_amount={0} />
      </div>
    """
  end
end
