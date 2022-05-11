defmodule Systems.DataDonation.S3Form do
  use Frameworks.Pixel.Component

  slot(default, required: true)

  @impl true
  def render(assigns) do
    ~F"""
      <form class="donate-form hidden" :on-submit={"donate", target: :live_view}>
        <input type="hidden" name="data" value="..." id="data">
        <#slot />
      </form>
    """
  end
end
