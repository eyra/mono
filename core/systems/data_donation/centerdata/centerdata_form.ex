defmodule Systems.DataDonation.CenterdataForm do
  use CoreWeb, :html

  attr(:session, :any, required: true)
  attr(:storage_info, :any, required: true)
  slot(:inner_block, required: true)

  def centerdata_form(assigns) do
    ~H"""
    <form id="donate-form" class="donate-form hidden" action={@session["url"]} method="post">
      <input type="hidden" name={@session["varname1"]} value="..." id="data">
      <input type="hidden" name="page" value={@session["page"]}>
      <input type="hidden" name="_respondent" value={@session["respondent"]}>
      <input type="hidden" name="token" value={@session["token"]}>
      <input type="hidden" name="button_next" value="Verder">
      <input type="hidden" name="quest" value={@storage_info.quest}>
      <%= render_slot(@inner_block) %>
    </form>
    <form id="decline-form" class="decline-form hidden" action={@session["url"]} method="post">
      <input type="hidden" name={@session["varname1"]} value="{ 'message': 'declined'}">
      <input type="hidden" name="page" value={@session["page"]}>
      <input type="hidden" name="_respondent" value={@session["respondent"]}>
      <input type="hidden" name="token" value={@session["token"]}>
      <input type="hidden" name="button_next" value="Verder">
      <input type="hidden" name="quest" value={@storage_info.quest}>
    </form>
    """
  end
end
