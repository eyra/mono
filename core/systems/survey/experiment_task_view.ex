defmodule Systems.Survey.ExperimentTaskView do
  use CoreWeb.UI.LiveComponent

  alias Frameworks.Utility.LiveCommand
  alias CoreWeb.UI.Navigation.ButtonBar

  prop(public_id, :integer, required: true)
  prop(title, :string, required: true)
  prop(email, :string, required: true)
  prop(call_to_action, :map, required: true)
  prop(contact_enabled?, :boolean, required: true)
  prop(owner, :map, required: true)

  @impl true
  def handle_event(
        "call-to-action",
        _params,
        %{assigns: %{call_to_action: %{live_command: live_command}}} = socket
      ) do
    {:noreply, live_command |> LiveCommand.execute(socket)}
  end

  defp action_map(%{
         public_id: public_id,
         title: title,
         call_to_action: %{label: label},
         contact_enabled?: contact_enabled?,
         owner: %{email: email},
         myself: myself
       }) do
    actions = %{
      call_to_action: %{
        action: %{type: :send, event: "call-to-action", target: myself},
        face: %{
          type: :primary,
          label: label
        }
      }
    }

    if contact_enabled? and email do
      actions
      |> Map.put(:contact, %{
        action: %{type: :href, href: contact_href(email, title, public_id)},
        face: %{type: :label, label: dgettext("eyra-assignment", "contact.button")}
      })
    else
      actions
    end
  end

  defp contact_href(email, title, nil) do
    "mailto:#{email}?subject=#{title}"
  end

  defp contact_href(email, title, public_id) do
    "mailto:#{email}?subject=[panl_id=#{public_id}] #{title}"
  end

  defp create_actions(%{call_to_action: call_to_action, contact: contact}),
    do: [call_to_action, contact]

  defp create_actions(%{call_to_action: call_to_action}), do: [call_to_action]

  def render(assigns) do
    ~F"""
    <div>
      <MarginY id={:button_bar_top} />
      <ButtonBar buttons={create_actions(action_map(assigns))} />
      <Spacing value="XL" />
    </div>
    """
  end
end
