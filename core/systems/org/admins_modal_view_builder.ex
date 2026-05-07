defmodule Systems.Org.AdminsModalViewBuilder do
  @moduledoc """
  ViewBuilder for the AdminsModalView.

  Provides the data needed by PeopleEditorComponent:
  - title: The modal title
  - people: Current org admins (owners)
  - users: Available users that can be added as admins
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account
  alias Systems.Org

  def view_model(org, _assigns) do
    people = Org.Public.list_owners(org)
    people_ids = Enum.map(people, & &1.id)

    # Get all creators who aren't already admins
    users =
      Account.Public.list_creators([:profile])
      |> Enum.reject(&(&1.id in people_ids))

    %{
      title: dgettext("eyra-admin", "org.admins.title"),
      people: people,
      users: users
    }
  end
end
