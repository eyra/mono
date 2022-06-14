defmodule Systems.DataDonation.FakeForm do
  use Frameworks.Pixel.Component

  slot(default, required: true)

  @impl true
  def render(assigns) do
    ~F"""
      <form id="donate-form" class="donate-form hidden" :on-submit={"donate", target: :live_view}>
        <input type="hidden" name="data" value="..." id="data">
        <#slot />
      </form>
      <form id="decline-form" class="decline-form hidden" :on-submit={"decline", target: :live_view}>
        <input type="hidden" name="data" value="{ 'message': 'declined'}" id="data">
      </form>
    """
  end
end
