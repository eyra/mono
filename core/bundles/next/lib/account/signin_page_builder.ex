defmodule Next.Account.SigninPageBuilder do
  import CoreWeb.Gettext
  import Frameworks.Utility.List

  import Core.FeatureFlags

  def view_model(_, assigns) do
    tabs = create_tabs(assigns)

    %{
      tabs: tabs,
      active_menu_item: :profile
    }
  end

  defp create_tabs(assigns) do
    tab_keys(assigns)
    |> Enum.map(&create_tab(&1, assigns))
  end

  defp tab_keys(%{user_type: "creator"}) do
    [:creator, :participant]
  end

  defp tab_keys(_) do
    [:participant, :creator]
  end

  defp create_tab(:participant, %{fabric: fabric, email: email}) do
    blocks =
      []
      |> append_if(:google, feature_enabled?(:member_google_sign_in))
      |> append_if(:password, feature_enabled?(:password_sign_in))
      |> insert_at_every(1, fn -> :seperator end)

    child =
      Fabric.prepare_child(fabric, :participant, Next.Account.ParticipantSigninView, %{
        email: email,
        blocks: blocks
      })

    %{
      id: :participant,
      ready: true,
      show_errors: false,
      title: dgettext("eyra-next", "participant.signin.title"),
      type: :fullpage,
      child: child
    }
  end

  defp create_tab(:creator, %{fabric: fabric, email: email}) do
    blocks =
      []
      |> append_if(:surfconext, feature_enabled?(:surfconext_sign_in))
      |> append_if(:password, feature_enabled?(:password_sign_in))
      |> insert_at_every(1, fn -> :seperator end)

    child =
      Fabric.prepare_child(fabric, :creator, Next.Account.CreatorSigninView, %{
        email: email,
        blocks: blocks
      })

    %{
      id: :creator,
      ready: true,
      show_errors: false,
      title: dgettext("eyra-next", "creator.signin.title"),
      type: :fullpage,
      child: child
    }
  end
end
