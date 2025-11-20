defmodule Systems.Account.ProfileTab do
  @moduledoc """
  Profile tab implementation.
  This tab is always visible for all users.
  """
  @behaviour Systems.Account.UserProfileTab

  use Gettext, backend: CoreWeb.Gettext

  @impl true
  def key, do: :profile

  @impl true
  def visible?(_user), do: true

  @impl true
  def build(user, fabric) do
    child =
      Fabric.prepare_child(fabric, :profile, Systems.Account.UserProfileForm, %{
        id: :profile_form,
        user: user
      })

    %{
      id: :profile,
      title: dgettext("eyra-account", "profile.tab.profile.title"),
      type: :fullpage,
      child: child,
      ready?: true
    }
  end
end
