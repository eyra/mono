defmodule Systems.Support.HelpdeskPage do
  use Systems.Content.Composer, :live_workspace

  @impl true
  def get_model(_params, _session, %{assigns: %{current_user: user}} = _socket) do
    user
  end

  @impl true
  def mount(params, _session, socket) do
    {
      :ok,
      socket
      |> assign(first: true, ticket_created: false)
      |> assign(initial_description: reference_description(params))
      |> compose_child(:helpdesk_form)
    }
  end

  def compose(:helpdesk_form, %{vm: %{ticket_created: true}}) do
    nil
  end

  @impl true
  def compose(:helpdesk_form, %{vm: %{user: user}, initial_description: description}) do
    %{
      module: Systems.Support.HelpdeskForm,
      params: %{user: user, initial_description: description}
    }
  end

  @impl true
  def handle_event("ticket_created", _params, socket) do
    {
      :noreply,
      socket
      |> assign(
        first: false,
        ticket_created: true,
        initial_description: ""
      )
      |> update_child(:helpdesk_form)
    }
  end

  def handle_event("next", _params, socket) do
    {
      :noreply,
      socket
      |> assign(ticket_created: false, first: true)
      |> update_child(:helpdesk_form)
    }
  end

  defp reference_description(params) do
    references =
      for key <- ["assignment_id", "task_id"],
          value = Map.get(params, key),
          is_binary(value),
          byte_size(value) <= 19,
          Regex.match?(~r/\A[1-9][0-9]*\z/, value) do
        "#{key}: #{value}"
      end

    Enum.join(references, "\n")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_workspace title={@vm.title} menus={@menus} modal={@modal} socket={@socket}>
      <div id="helpdesk_content" phx-hook="LiveContent" data-show-errors={true}>
      <Area.content>
        <Area.form>
          <Margin.y id={:page_top} />
          <Text.title2><%= dgettext("eyra-support", "form.title") %></Text.title2>
          <%= if @ticket_created do %>
            <Text.body_large><%= @vm.next.description %></Text.body_large>
            <.spacing value="M" />
            <Button.dynamic_bar buttons={[@vm.next.button]} />
          <% else %>
            <Text.body_large><%= @vm.first.description %></Text.body_large>
            <.spacing value="XL" />
            <.child name={:helpdesk_form} fabric={@fabric} />
          <% end %>
          </Area.form>
        </Area.content>
      </div>
    </.live_workspace>
    """
  end
end
