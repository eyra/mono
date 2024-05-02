defmodule Systems.Pool.ParticipantPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :pool_participant

  import CoreWeb.UI.Member
  alias Core.Accounts
  import CoreWeb.UI.Content

  alias Frameworks.Pixel.Text
  alias Frameworks.Utility.ViewModelBuilder

  alias Systems.{
    Advert,
    Budget
  }

  @impl true
  def mount(%{"id" => user_id}, _session, %{assigns: assigns} = socket) do
    user = Accounts.get_user!(user_id, [:features, :profile])
    # assigning user as the wallet owner, not to be confused with current_user
    socket = assign(socket, :user, user)

    wallets =
      Budget.Public.list_wallets(user)
      |> Enum.map(&Budget.WalletViewBuilder.view_model(&1, assigns))

    advert_preload = Advert.Model.preload_graph(:down)

    contributions =
      user
      |> Advert.Public.list_subject_adverts(preload: advert_preload)
      |> Enum.map(&ViewModelBuilder.view_model(&1, {__MODULE__, :contribution}, assigns))

    {
      :ok,
      socket
      |> assign(
        wallets: wallets,
        contributions: contributions
      )
      |> update_member()
    }
  end

  defp update_member(%{assigns: %{user: user}} = socket) do
    socket
    |> assign(member: to_member(user))
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
      [email | Accounts.Features.get_student_classes(features)]
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

  # data(member, :any, default: nil)
  # data(wallets, :any)
  # data(contributions, :any)

  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("link-studentpool", "participant.title")} menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if @member do %>
          <.member {@member} />
        <% end %>
        <Margin.y id={:page_top} />

        <%= if Enum.count(@wallets) > 0 do %>
          <div>
            <Text.title2>
              <%= dgettext("link-dashboard", "book.accounts.title") %>
            </Text.title2>
            <Budget.WalletView.list items={@wallets} />
            <.spacing value="XL" />
          </div>
        <% end %>

        <%= if Enum.count(@contributions) > 0 do %>
          <div>
            <Text.title2>
              <%= dgettext("eyra-advert", "advert.subject.title") %>
              <span class="text-primary"> <%= Enum.count(@contributions) %></span>
            </Text.title2>
            <.list items={@contributions} />
            <.spacing value="XL" />
          </div>
        <% end %>

      </Area.content>
    </.workspace>
    """
  end
end
