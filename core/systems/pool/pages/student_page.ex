defmodule Systems.Pool.StudentPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :pool_student

  alias Core.Accounts
  alias CoreWeb.UI.{WalletList, ContentList, Member}

  alias Frameworks.Pixel.Text.{Title2}
  alias Frameworks.Utility.ViewModelBuilder

  alias Systems.{
    Campaign,
    Budget,
    Pool
  }

  data(member, :any, default: nil)
  data(wallets, :any)
  data(contributions, :any)

  @impl true
  def mount(%{"id" => user_id}, _session, socket) do
    user = Accounts.get_user!(user_id, [:features, :profile])

    wallets =
      Budget.Context.list_wallets(user)
      |> Enum.map(&Pool.Builders.Wallet.view_model(&1, user, url_resolver(socket)))

    campaign_preload = Campaign.Model.preload_graph(:full)

    contributions =
      user
      |> Campaign.Context.list_subject_campaigns(preload: campaign_preload)
      |> Enum.map(
        &ViewModelBuilder.view_model(&1, {__MODULE__, :contribution}, user, url_resolver(socket))
      )

    {
      :ok,
      socket
      |> assign(
        user: user,
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
      [email | Accounts.Features.get_scholar_classes(features)]
      |> Enum.join(" ▪︎ ")

    action = %{type: :href, href: "mailto:#{email}"}

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

  @impl true
  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("link-studentpool", "student.title")} menus={@menus}>
      <ContentArea>
        <MarginY id={:page_top} />
        <Member :if={@member} vm={@member} />
        <MarginY id={:page_top} />
        <div :if={Enum.count(@wallets) > 0}>
          <Title2>
            {dgettext("link-dashboard", "book.accounts.title")}
          </Title2>
          <WalletList items={@wallets} />
          <Spacing value="XL" />
        </div>
        <div :if={Enum.count(@contributions) > 0}>
          <Title2>
            {dgettext("eyra-campaign", "campaign.subject.title")}
            <span class="text-primary">
              {Enum.count(@contributions)}</span>
          </Title2>
          <ContentList items={@contributions} />
          <Spacing value="XL" />
        </div>
      </ContentArea>
    </Workspace>
    """
  end
end
