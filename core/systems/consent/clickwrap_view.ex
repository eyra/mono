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
    selected? = signature != nil

    {
      :ok,
      socket
      |> assign(
        id: id,
        revision: revision,
        user: user,
        signature: signature,
        selected?: selected?
      )
      |> update_form()
      |> update_continue_button()
      |> update_checkbox()
    }
  end

  defp update_form(%{assigns: %{selected?: selected?}} = socket) do
    form = to_form(%{"signature_check" => selected?})
    assign(socket, form: form)
  end

  defp update_continue_button(%{assigns: %{selected?: selected?, myself: myself}} = socket) do
    continue_button = %{
      action: %{type: :send, event: "continue", target: myself},
      face: %{
        type: :primary,
        label: dgettext("eyra-assignment", "onboarding.consent.continue.button")
      },
      enabled?: selected?
    }

    assign(socket, continue_button: continue_button)
  end

  defp update_checkbox(socket) do
    checkbox = %{
      field: :signature_check,
      label_text: dgettext("eyra-consent", "onboarding.consent.checkbox")
    }

    assign(socket, checkbox: checkbox)
  end

  @impl true
  def handle_event(
        "toggle",
        %{"checkbox" => _checkbox},
        %{assigns: %{selected?: selected?}} = socket
      ) do
    {
      :noreply,
      socket
      |> assign(selected?: not selected?)
      |> update_form()
      |> update_continue_button()
    }
  end

  @impl true
  def handle_event("continue", _payload, socket) do
    {
      :noreply,
      socket |> handle_continue()
    }
  end

  def handle_continue(%{assigns: %{signature: nil, revision: revision, user: user}} = socket) do
    {:ok, signature} = Consent.Public.create_signature(revision, user)

    socket
    |> assign(signature: signature)
    |> handle_continue()
  end

  def handle_continue(%{assigns: %{signature: %{id: _}}} = socket) do
    socket |> send_event(:parent, "continue")
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
          <div class="wysiwig">
            <%= raw @revision.source %>
          </div>
          <.spacing value="M" />
          <.form id={@id} :let={form} for={@form} phx-target={@myself} >
            <.checkbox {@checkbox} form={form} />
          </.form>
          <.wrap>
            <Button.dynamic {@continue_button} />
          </.wrap>
      </div>
    """
  end
end
