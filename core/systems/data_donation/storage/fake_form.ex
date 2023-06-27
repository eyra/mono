defmodule Systems.DataDonation.FakeForm do
  use CoreWeb, :html

  slot(:inner_block, required: true)

  def fake_form(assigns) do
    ~H"""
    <form id="donate-form" class="donate-form hidden" phx-submit="donate">
      <input type="hidden" name="data" value="..." id="data">
      <%= render_slot(@inner_block) %>
    </form>
    <form id="decline-form" class="decline-form hidden" phx-submit="decline">
      <input type="hidden" name="data" value="{ 'message': 'declined'}" id="data">
    </form>
    """
  end
end
