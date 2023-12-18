defmodule Systems.Consent.ClickWrapView do
  # Clickwrap agreements are a type of electronic signature that involves a user
  # clicking a simple button to accept the agreement.

  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  alias Systems.{
    Consent
  }

  @impl true
  def update(%{id: id, revision: revision, user: user}, socket) do
    signature = Consent.Public.get_signature(revision, user)

    {
      :ok,
      socket
      |> assign(
        id: id,
        revision: revision,
        user: user,
        signature: signature
      )
      |> update_validation()
      |> update_buttons()
    }
  end

  defp update_buttons(%{assigns: %{myself: myself}} = socket) do
    accept_button = %{
      action: %{type: :send, event: "accept", target: myself},
      face: %{
        type: :primary,
        label: dgettext("eyra-consent", "click_wrap.accept.button")
      }
    }

    decline_button = %{
      action: %{type: :send, event: "decline", target: myself},
      face: %{
        type: :label,
        label: dgettext("eyra-consent", "click_wrap.decline.button")
      }
    }

    assign(socket, buttons: [accept_button, decline_button])
  end

  defp update_validation(socket) do
    validation = dgettext("eyra-consent", "click_wrap.consent.validation")
    assign(socket, validation: validation)
  end

  @impl true
  def handle_event("accept", _payload, socket) do
    {
      :noreply,
      socket |> handle_accept()
    }
  end

  @impl true
  def handle_event("decline", _payload, socket) do
    {
      :noreply,
      socket |> handle_decline()
    }
  end

  def handle_accept(%{assigns: %{signature: nil, revision: revision, user: user}} = socket) do
    {:ok, signature} = Consent.Public.create_signature(revision, user)

    socket
    |> assign(signature: signature)
    |> handle_accept()
  end

  def handle_accept(%{assigns: %{signature: %{id: _}}} = socket) do
    socket |> send_event(:parent, "continue")
  end

  def handle_decline(socket) do
    socket |> send_event(:parent, "decline")
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <div class="wysiwyg">
          <%= raw @revision.source %>
        </div>
        <.spacing value="L" />
        <Text.title6><%= @validation %></Text.title6>
        <.spacing value="XS" />
        <div class="flex flex-row gap-4">
          <%= for button <- @buttons do %>
            <Button.dynamic {button} />
          <% end %>
        </div>
      </div>
    """
  end
end
