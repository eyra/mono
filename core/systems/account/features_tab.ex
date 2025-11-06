defmodule Systems.Account.FeaturesTab do
  @moduledoc """
  Features tab implementation.
  This tab is only visible for PANL participants.
  """
  @behaviour Systems.Account.UserProfileTab

  use Gettext, backend: CoreWeb.Gettext

  @impl true
  def key, do: :features

  @impl true
  def visible?(user), do: Systems.Pool.Public.panl_participant?(user)

  @impl true
  def build(user, fabric) do
    child =
      Fabric.prepare_child(fabric, :features, Systems.Account.FeaturesForm, %{
        user: user
      })

    %{
      id: :features,
      title: dgettext("eyra-account", "profile.tab.features.title"),
      type: :fullpage,
      child: child,
      ready?: true
    }
  end
end
