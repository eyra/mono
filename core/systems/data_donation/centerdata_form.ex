defmodule Systems.DataDonation.CenterdataForm do
  use Frameworks.Pixel.Component

  prop(session, :any, required: true)
  slot(default, required: true)

  @impl true
  def render(assigns) do
    ~F"""
      <form class="donate-form hidden" action={@session["url"]} method="post">
        <input type="hidden" name={@session["varname1"]} value="..." id="data">
        <input type="hidden" name="page" value={@session["page"]}>
        <input type="hidden" name="_respondent" value={@session["respondent"]}>
        <input type="hidden" name="token" value={@session["token"]}>
        <input type="hidden" name="button_next" value="Verder">
        <input type="hidden" name="quest" value="test_arnaud">
        <#slot />
      </form>
    """
  end
end
