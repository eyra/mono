defmodule Next.Account.SigninPageBuilder do
  import CoreWeb.Gettext

  def view_model(_, assigns) do
    tabs = create_tabs(assigns)

    %{
      tabs: tabs,
      active_menu_item: :profile
    }
  end

  defp create_tabs(assigns) do
    [:participant, :creator]
    |> Enum.map(&create_tab(&1, assigns))
  end

  defp create_tab(:participant, %{fabric: fabric, email: email}) do
    child =
      Fabric.prepare_child(fabric, :participant, Next.Account.ParticipantSigninView, %{
        email: email
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
    child =
      Fabric.prepare_child(fabric, :creator, Next.Account.CreatorSigninView, %{
        email: email
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
