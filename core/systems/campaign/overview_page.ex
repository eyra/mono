defmodule Systems.Campaign.OverviewPage do
  @moduledoc """
   The recruitment page for researchers.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :recruitment
  use CoreWeb.UI.PlainDialog

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias CoreWeb.UI.PlainDialog
  alias CoreWeb.UI.SelectorDialog
  alias Frameworks.Pixel.Button.PrimaryLiveViewButton

  alias Link.Marketplace.Card, as: CardVM
  alias Frameworks.Pixel.Card.DynamicCampaign
  alias Frameworks.Pixel.Grid.DynamicGrid
  alias Frameworks.Pixel.Text.Title2
  alias Frameworks.Pixel.Button.Action.Send
  alias Frameworks.Pixel.Button.Face.PlainIcon
  alias Frameworks.Pixel.ShareView

  data(campaigns, :list, default: [])
  data(share_dialog, :map)
  data(selector_dialog, :map)

  alias Systems.{
    Campaign,
    Assignment
  }

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
        dialog: nil,
        share_dialog: nil,
        selector_dialog: nil
      )
      |> update_campaigns()
      |> update_menus()
    }
  end

  defp update_campaigns(%{assigns: %{current_user: user}} = socket) do
    preload = Campaign.Model.preload_graph(:full)

    campaigns =
      user
      |> Campaign.Context.list_owned_campaigns(preload: preload)
      |> Enum.map(&CardVM.campaign_researcher(&1, socket))

    socket
    |> assign(
      campaigns: campaigns,
      dialog: nil,
      share_dialog: nil,
      selector_dialog: nil
    )
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_event("delete", %{"item" => campaign_id}, socket) do
    item = dgettext("link-ui", "delete.confirm.campaign")
    title = String.capitalize(dgettext("eyra-ui", "delete.confirm.title", item: item))
    text = String.capitalize(dgettext("eyra-ui", "delete.confirm.text", item: item))
    confirm_label = dgettext("eyra-ui", "delete.confirm.label")

    {
      :noreply,
      socket
      |> assign(campaign_id: String.to_integer(campaign_id))
      |> confirm("delete", title, text, confirm_label)
    }
  end

  @impl true
  def handle_event("delete_confirm", _params, %{assigns: %{campaign_id: campaign_id}} = socket) do
    Campaign.Context.delete(campaign_id)

    {
      :noreply,
      socket
      |> assign(
        campaign_id: nil,
        dialog: nil
      )
      |> update_campaigns()
      |> update_menus()
    }
  end

  @impl true
  def handle_event("delete_cancel", _params, socket) do
    {:noreply, socket |> assign(campaign_id: nil, dialog: nil)}
  end

  @impl true
  def handle_event("close_share_dialog", _, socket) do
    IO.puts("close_share_dialog")
    {:noreply, socket |> assign(share_dialog: nil)}
  end

  @impl true
  def handle_event("share", %{"item" => campaign_id}, %{assigns: %{current_user: user}} = socket) do
    researchers =
      Core.Accounts.list_researchers([:profile])
      # filter current user
      |> Enum.filter(&(&1.id != user.id))

    owners =
      campaign_id
      |> String.to_integer()
      |> Campaign.Context.get!()
      |> Campaign.Context.list_owners([:profile])
      # filter current user
      |> Enum.filter(&(&1.id != user.id))

    share_dialog = %{
      content_id: campaign_id,
      content_name: dgettext("eyra-campaign", "share.dialog.content"),
      group_name: dgettext("eyra-campaign", "share.dialog.group"),
      users: researchers,
      shared_users: owners
    }

    {
      :noreply,
      socket |> assign(share_dialog: share_dialog)
    }
  end

  @impl true
  def handle_event("duplicate", %{"item" => campaign_id}, socket) do
    preload = Campaign.Model.preload_graph(:full)
    campaign = Campaign.Context.get!(String.to_integer(campaign_id), preload)

    Campaign.Assembly.copy(campaign)

    {
      :noreply,
      socket
      |> update_campaigns()
      |> update_menus()
    }
  end

  @impl true
  def handle_event("create_campaign", _params, socket) do
    selector_dialog = %{
      title: dgettext("link-campaign", "create.campaign.dialog.title"),
      text: dgettext("link-campaign", "create.campaign.dialog.text"),
      items: Assignment.ToolTypes.labels(nil),
      ok_button_text: dgettext("link-campaign", "create.campaign.dialog.ok.button"),
      cancel_button_text: dgettext("eyra-ui", "cancel.button"),
      target: self()
    }

    {:noreply, socket |> assign(selector_dialog: selector_dialog)}
  end

  @impl true
  def handle_info(%{selector: :ok, selected: tool_type}, socket) do
    tool = create_campaign(socket, tool_type)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Campaign.ContentPage, tool.id))}
  end

  @impl true
  def handle_info(%{selector: :cancel}, socket) do
    {:noreply, socket |> assign(selector_dialog: nil)}
  end

  @impl true
  def handle_info({:card_click, %{action: :edit, id: id}}, socket) do
    {:noreply,
     push_redirect(socket, to: CoreWeb.Router.Helpers.live_path(socket, Campaign.ContentPage, id))}
  end

  @impl true
  def handle_info({:share_view, :close}, socket) do
    {:noreply, socket |> assign(share_dialog: nil)}
  end

  @impl true
  def handle_info({:share_view, %{add: user, content_id: campaign_id}}, socket) do
    campaign_id
    |> Campaign.Context.get!()
    |> Campaign.Context.add_owner!(user)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:share_view, %{remove: user, content_id: campaign_id}}, socket) do
    campaign_id
    |> Campaign.Context.get!()
    |> Campaign.Context.remove_owner!(user)

    {:noreply, socket}
  end

  defp create_campaign(%{assigns: %{current_user: user}} = _socket, tool_type) do
    title = dgettext("eyra-dashboard", "default.study.title")
    Campaign.Assembly.create(user, title, tool_type)
  end

  def render(assigns) do
    ~F"""
    <Workspace title={dgettext("link-survey", "title")} menus={@menus}>
      <div
        :if={@share_dialog}
        class="fixed z-20 left-0 top-0 w-full h-full bg-black bg-opacity-20"
        phx-click="close_share_dialog"
      >
        <div class="flex flex-row items-center justify-center w-full h-full">
          <ShareView id={:share_dialog} {...@share_dialog} />
        </div>
      </div>

      <div :if={@dialog != nil} class="fixed z-40 left-0 top-0 w-full h-full bg-black bg-opacity-20">
        <div class="flex flex-row items-center justify-center w-full h-full">
          <PlainDialog {...@dialog} />
        </div>
      </div>

      <div
        :if={@selector_dialog != nil}
        class="fixed z-40 left-0 top-0 w-full h-full bg-black bg-opacity-20"
      >
        <div class="flex flex-row items-center justify-center w-full h-full">
          <SelectorDialog id={:selector_dialog} {...@selector_dialog} />
        </div>
      </div>

      <ContentArea>
        <MarginY id={:page_top} />
        <Case value={Enum.count(@campaigns) > 0}>
          <True>
            <div class="flex flex-row items-center">
              <div class="h-full">
                <Title2 margin="">{dgettext("link-survey", "campaign.overview.title")}</Title2>
              </div>
              <div class="flex-grow">
              </div>
              <div class="h-full pt-2px lg:pt-1">
                <Send vm={%{event: "create_campaign"}}>
                  <div class="sm:hidden">
                    <PlainIcon vm={label: dgettext("link-survey", "add.new.button.short"), icon: :forward} />
                  </div>
                  <div class="hidden sm:block">
                    <PlainIcon vm={label: dgettext("link-survey", "add.new.button"), icon: :forward} />
                  </div>
                </Send>
              </div>
            </div>
            <MarginY id={:title2_bottom} />
            <DynamicGrid>
              <div :for={campaign <- @campaigns}>
                <DynamicCampaign
                  path_provider={CoreWeb.Endpoint}
                  card={campaign}
                  click_event_data={%{action: :edit, id: campaign.edit_id}}
                />
              </div>
            </DynamicGrid>
            <Spacing value="L" />
          </True>
          <False>
            <Empty
              title={dgettext("link-survey", "empty.title")}
              body={dgettext("link-survey", "empty.description")}
              illustration="cards"
            />
            <Spacing value="L" />
            <PrimaryLiveViewButton
              label={dgettext("link-survey", "add.first.button")}
              event="create_campaign"
            />
          </False>
        </Case>
      </ContentArea>
    </Workspace>
    """
  end
end
