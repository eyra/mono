defmodule Link.Console do
  @moduledoc """
  The console screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :console

  alias Systems.{
    Campaign,
    Budget
  }

  alias Frameworks.Utility.ViewModelBuilder

  alias CoreWeb.UI.ContentList
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias Frameworks.Pixel.Text.{Title2}
  alias Systems.NextAction

  data(wallets, :any)
  data(contributions, :any)
  data(content_items, :any)
  data(current_user, :any)
  data(next_best_action, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = Campaign.Model.preload_graph(:full)

    next_best_action = NextAction.Public.next_best_action(url_resolver(socket), user)

    wallets =
      Budget.Public.list_wallets(user)
      |> filter_wallets()
      |> Enum.map(&Budget.WalletViewBuilder.view_model(&1, user, url_resolver(socket)))

    contributions =
      user
      |> Campaign.Public.list_subject_campaigns(preload: preload)
      |> Enum.map(
        &ViewModelBuilder.view_model(&1, {__MODULE__, :contribution}, user, url_resolver(socket))
      )

    content_items =
      user
      |> Campaign.Public.list_owned_campaigns(preload: preload)
      |> Enum.map(
        &ViewModelBuilder.view_model(&1, {__MODULE__, :content}, user, url_resolver(socket))
      )

    socket =
      socket
      |> update_menus()
      |> assign(
        next_best_action: next_best_action,
        wallets: wallets,
        contributions: contributions,
        content_items: content_items
      )

    {:ok, socket}
  end

  defp filter_wallets(wallets) do
    wallets
    |> Enum.filter(&Budget.Public.wallet_is_active?(&1))
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    socket |> update_menus()
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("link-dashboard", "title")} menus={@menus}>
      <ContentArea>
        <MarginY id={:page_top} />
        <div :if={@next_best_action} class="mb-6 md:mb-10">
          <NextAction.HighlightView vm={@next_best_action} />
        </div>
        <div :if={Enum.count(@wallets) > 0}>
          <Title2>
            {dgettext("link-dashboard", "book.accounts.title")}
          </Title2>
          <Budget.WalletList items={@wallets} />
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
        <div :if={Enum.count(@content_items) > 0}>
          <Title2>
            {dgettext("link-dashboard", "recent-items.title")}
          </Title2>
          <ContentList items={@content_items} />
          <Spacing value="XL" />
        </div>
        <div :if={Enum.count(@contributions) + Enum.count(@content_items) == 0}>
          <Empty
            title={dgettext("eyra-dashboard", "empty.title")}
            body={dgettext("eyra-dashboard", "empty.description")}
            illustration="items"
          />
        </div>
      </ContentArea>
    </Workspace>
    """
  end
end
