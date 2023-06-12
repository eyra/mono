defmodule Link.Console.Page do
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

  import CoreWeb.UI.Content
  import CoreWeb.Layouts.Workspace.Component

  alias Frameworks.Pixel.Text
  alias Systems.NextAction

  def mount(_params, _session, %{assigns: %{current_user: user} = assigns} = socket) do
    preload = Campaign.Model.preload_graph(:full)

    next_best_action = NextAction.Public.next_best_action(user)

    wallets =
      Budget.Public.list_wallets(user)
      |> filter_wallets()
      |> Enum.map(&Budget.WalletViewBuilder.view_model(&1, user))

    contributions =
      user
      |> Campaign.Public.list_subject_campaigns(preload: preload)
      |> Enum.map(&ViewModelBuilder.view_model(&1, {__MODULE__, :contribution}, assigns))

    content_items =
      user
      |> Campaign.Public.list_owned_campaigns(preload: preload)
      |> Enum.map(&ViewModelBuilder.view_model(&1, {__MODULE__, :content}, assigns))

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

  # data(wallets, :any)
  # data(contributions, :any)
  # data(content_items, :any)
  # data(current_user, :any)
  # data(next_best_action, :any)
  @impl true
  def render(assigns) do
    ~H"""
    <.workspace title={dgettext("link-dashboard", "title")} menus={@menus}>
      <Area.content>
        <Margin.y id={:page_top} />
        <%= if @next_best_action do %>
          <div class="mb-6 md:mb-10">
            <NextAction.View.highlight {@next_best_action} />
          </div>
        <% end %>
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
              <%= dgettext("eyra-campaign", "campaign.subject.title") %>
              <span class="text-primary">
                <%= Enum.count(@contributions) %></span>
            </Text.title2>
            <.list items={@contributions} />
            <.spacing value="XL" />
          </div>
        <% end %>
        <%= if Enum.count(@content_items) > 0 do %>
          <div>
            <Text.title2>
              <%= dgettext("link-dashboard", "recent-items.title") %>
            </Text.title2>
            <.list items={@content_items} />
            <.spacing value="XL" />
          </div>
        <% end %>
        <%= if Enum.count(@contributions) + Enum.count(@content_items) == 0 do %>
          <div>
            <.empty
              title={dgettext("eyra-dashboard", "empty.title")}
              body={dgettext("eyra-dashboard", "empty.description")}
              illustration="items"
            />
          </div>
        <% end %>
      </Area.content>
    </.workspace>
    """
  end
end
