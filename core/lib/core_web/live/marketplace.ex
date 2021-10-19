defmodule CoreWeb.Marketplace do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :marketplace

  import Core.Authorization

  alias Systems.{
    Campaign
  }

  alias Core.Accounts
  alias Systems.Campaign
  alias Core.DataDonation
  alias Core.Promotions
  alias Core.Content

  alias CoreWeb.ViewModel.Card, as: CardVM
  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias EyraUI.Card.{PrimaryStudy, SecondaryStudy, ButtonCard}
  alias EyraUI.Text.{Title2}
  alias EyraUI.Grid.{DynamicGrid}

  data(highlighted_count, :any)
  data(owned_campaigns, :any)
  data(subject_campaigns, :any)
  data(available_campaigns, :any)
  data(available_count, :any)
  data(current_user, :any)

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = [data_donation_tool: [:promotion]]

    owned_campaigns =
      user
      |> Campaign.Context.list_owned_campaigns(preload: preload)
      |> Enum.map(&CardVM.primary_campaign(&1, socket))

    subject_campaigns =
      user
      |> Campaign.Context.list_data_donation_subject_campaigns(preload: preload)
      |> Enum.map(&CardVM.primary_campaign(&1, socket))

    highlighted_campaigns = owned_campaigns ++ subject_campaigns
    highlighted_count = Enum.count(highlighted_campaigns)

    exclusion_list =
      highlighted_campaigns
      |> Stream.map(fn campaign -> campaign.id end)
      |> Enum.into(MapSet.new())

    available_campaigns =
      Campaign.Context.list_accepted_campaigns([DataDonation.Tool],
        exclude: exclusion_list,
        preload: preload
      )
      |> Enum.map(&CardVM.primary_campaign(&1, socket))

    available_count = Enum.count(available_campaigns)

    socket =
      socket
      |> update_menus()
      |> assign(highlighted_count: highlighted_count)
      |> assign(owned_campaigns: owned_campaigns)
      |> assign(subject_campaigns: subject_campaigns)
      |> assign(available_campaigns: available_campaigns)
      |> assign(available_count: available_count)

    {:ok, socket}
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def handle_info({:card_click, %{action: :edit, id: id}}, socket) do
    {:noreply,
     push_redirect(socket, to: Routes.live_path(socket, CoreWeb.DataDonation.Content, id))}
  end

  def handle_info({:card_click, %{action: :public, id: id}}, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Promotion.Public, id))}
  end

  @impl true
  def handle_event("create_tool", _params, socket) do
    tool = create_tool(socket)

    {:noreply,
     push_redirect(socket, to: Routes.live_path(socket, CoreWeb.DataDonation.Content, tool.id))}
  end

  defp create_tool(socket) do
    user = socket.assigns.current_user
    profile = user |> Accounts.get_profile()

    title = dgettext("eyra-marketplace", "default.study.title")

    changeset =
      %Campaign.Model{}
      |> Campaign.Model.changeset(%{title: title})

    tool_attrs = create_tool_attrs()
    promotion_attrs = create_promotion_attrs(title, user, profile)

    with {:ok, campaign} <- Campaign.Context.create(changeset, user),
         {:ok, _author} <- Campaign.Context.add_author(campaign, user),
         {:ok, _crew} <- Campaign.Context.create_crew(campaign),
         {:ok, tool_content_node} <- Content.Nodes.create(%{ready: false}),
         {:ok, promotion_content_node} <-
           Content.Nodes.create(%{ready: false}, tool_content_node),
         {:ok, promotion} <- Promotions.create(promotion_attrs, campaign, promotion_content_node),
         {:ok, tool} <-
           DataDonation.Tools.create(tool_attrs, campaign, promotion, tool_content_node) do
      tool
    end
  end

  defp create_tool_attrs() do
    %{
      reward_currency: :eur
    }
  end

  defp create_promotion_attrs(title, user, profile) do
    %{
      title: title,
      marks: ["uu"],
      plugin: "data_donation",
      banner_photo_url: profile.photo_url,
      banner_title: user.displayname,
      banner_subtitle: profile.title,
      banner_url: nil
    }
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("eyra-marketplace", "title") }}
        menus={{ @menus }}
      >
        <ContentArea>
          <MarginY id={{:page_top}} />
          <Title2>
            {{ dgettext("eyra-marketplace", "highlighted.title") }}
            <span class="text-primary"> {{ @highlighted_count }}</span>
          </Title2>
          <DynamicGrid>
            <div :for={{ card <- @owned_campaigns  }} >
              <PrimaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :edit, id: card.edit_id } }} />
            </div>
            <div :for={{ card <- @subject_campaigns  }} >
              <PrimaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :public, id: card.open_id } }} />
            </div>
            <div :if={{ can_access?(@current_user, CoreWeb.Study.New) }} >
              <ButtonCard
                title={{dgettext("eyra-marketplace", "add.card.title")}}
                image={{Routes.static_path(@socket, "/images/plus-primary.svg")}}
                event="create_tool" />
            </div>
          </DynamicGrid>
          <div class="mt-6 lg:mt-10"/>
          <Title2>
            {{ dgettext("eyra-marketplace", "marketplace.title") }}
            <span class="text-primary"> {{ @available_count }}</span>
          </Title2>
          <DynamicGrid>
            <div :for={{ card <- @available_campaigns  }} class="mb-1" >
              <SecondaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :public, id: card.open_id } }} />
            </div>
          </DynamicGrid>
        </ContentArea>
      </Workspace>
    """
  end
end
