defmodule Systems.Support.HelpdeskPage do
  use Systems.Content.Composer, :live_workspace

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}} = _socket) do
    user
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> compose_child(:helpdesk_form)}
  end

  @impl true
  def compose(:helpdesk_form, %{vm: %{user: user}}) do
    %{
      module: Systems.Support.HelpdeskForm,
      params: %{user: user}
    }
  end

  @impl true
  def handle_view_model_updated(socket), do: socket

  @impl true
  def handle_uri(socket), do: socket

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modal={@modal} popup={@popup} dialog={@dialog}>
      <Area.content>
        <Area.form>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-support", "form.title") %></Text.title2>
          <Text.body_large><%= dgettext("eyra-support", "form.description") %>
          </Text.body_large>
        </Area.form>
      </Area.content>

      <.spacing value="XL" />

      <.child name={:helpdesk_form} fabric={@fabric} />
    </.live_workspace>
    """
  end
end
