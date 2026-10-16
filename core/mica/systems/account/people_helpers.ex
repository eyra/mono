defmodule Systems.Account.PeopleHelpers do
  @moduledoc """
  Shared helpers for building people/user display items with confirmation rows.
  """
  use Gettext, backend: CoreWeb.Gettext

  @doc """
  Builds a confirmation row map for self-removal UI.

  Returns a map with:
  - confirm_row_visible?: true
  - confirm_row_text: localized confirmation text
  - confirm_row_action_buttons: confirm and cancel buttons
  """
  def build_confirm_row(user_id, target) do
    %{
      confirm_row_visible?: true,
      confirm_row_text: dgettext("eyra-account", "people.confirm_remove.text"),
      confirm_row_action_buttons: [
        %{
          action: %{type: :send, event: "remove", item: user_id, target: target},
          face: %{
            type: :primary,
            label: dgettext("eyra-account", "people.confirm_remove.label")
          }
        },
        %{
          action: %{type: :send, event: "cancel_remove", item: user_id, target: target},
          face: %{type: :primary, label: dgettext("eyra-account", "people.cancel_remove.label")}
        }
      ]
    }
  end
end
