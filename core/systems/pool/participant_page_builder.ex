defmodule Systems.Pool.ParticipantPageBuilder do
  alias Frameworks.Utility.ViewModelBuilder

  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Account
  alias Systems.Budget
  alias Systems.Advert

  def view_model(user, assigns) do
    wallets =
      Budget.Public.list_wallets(user)
      |> Enum.map(&Budget.WalletViewBuilder.view_model(&1, assigns))

    contributions =
      user
      |> Advert.Public.list_by_participant(preload: Advert.Model.preload_graph(:down))
      |> Enum.map(&ViewModelBuilder.view_model(&1, {__MODULE__, :contribution}, assigns))

    %{
      member: to_member(user),
      wallets: wallets,
      contributions: contributions,
      active_menu_item: :home
    }
  end

  defp to_member(%{
         email: email,
         profile: %{
           fullname: fullname,
           photo_url: photo_url
         },
         features:
           %{
             gender: gender
           } = features
       }) do
    subtitle =
      [email | Account.FeaturesModel.get_student_classes(features)]
      |> Enum.join(" ▪︎ ")

    action = %{type: :http_get, to: "mailto:#{email}"}

    %{
      title: fullname,
      subtitle: subtitle,
      photo_url: photo_url,
      gender: gender,
      button_large: %{
        action: action,
        face: %{
          type: :primary,
          label: dgettext("eyra-ui", "mailto.button"),
          bg_color: "bg-tertiary",
          text_color: "text-grey1"
        }
      },
      button_small: %{
        action: action,
        face: %{type: :icon, icon: :contact_tertiary}
      }
    }
  end
end
