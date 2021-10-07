defmodule Link.Survey.Overview do
  @moduledoc """
   The surveys screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :surveys

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias EyraUI.Button.PrimaryLiveViewButton
  alias Core.Studies
  alias Core.Studies.Study
  alias Core.Accounts
  alias Core.Survey.Tools
  alias Core.Content
  alias Core.Promotions
  alias Core.Pools
  alias Core.Pools.Submissions

  alias Link.Marketplace.Card, as: CardVM
  alias EyraUI.Card.PrimaryStudy
  alias EyraUI.Grid.DynamicGrid
  alias EyraUI.Text.Title2
  alias EyraUI.Button.Action.Send
  alias EyraUI.Button.Face.Forward
  import Core.ImageCatalog, only: [image_catalog: 0]

  data(surveys, :map, default: [])

  def mount(_params, _session, %{assigns: %{current_user: user}} = socket) do
    preload = [survey_tool: [promotion: [:submission]]]

    surveys =
      user
      |> Studies.list_owned_studies(preload: preload)
      # Temp: filter out labs
      |> Enum.filter(& &1.survey_tool)
      |> Enum.map(&CardVM.primary_study_researcher(&1, socket))

    {:ok,
     socket
     |> assign(surveys: surveys)
     |> update_menus()}
  end


  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  @impl true
  def handle_event("create_tool", _params, socket) do
    tool = create_tool(socket)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Link.Survey.Content, tool.id))}
  end

  def handle_info({:card_click, %{action: :edit, id: id}}, socket) do
    {:noreply,
     push_redirect(socket, to: CoreWeb.Router.Helpers.live_path(socket, Link.Survey.Content, id))}
  end

  defp create_tool(socket) do
    user = socket.assigns.current_user
    profile = user |> Accounts.get_profile()

    title = dgettext("eyra-dashboard", "default.study.title")

    changeset =
      %Study{}
      |> Study.changeset(%{title: title})

    tool_attrs = create_tool_attrs()
    promotion_attrs = create_promotion_attrs(title, user, profile)

    pool = Pools.get_by_name(:vu_students)

    with {:ok, study} <- Studies.create_study(changeset, user),
         {:ok, _author} <- Studies.add_author(study, user),
         {:ok, tool_content_node} <- Content.Nodes.create(%{ready: false}),
         {:ok, promotion_content_node} <-
           Content.Nodes.create(%{ready: false}, tool_content_node),
         {:ok, promotion} <- Promotions.create(promotion_attrs, study, promotion_content_node),
         {:ok, submission_content_node} <-
           Content.Nodes.create(%{ready: true}, promotion_content_node),
         {:ok, _submission} <- Submissions.create(promotion, pool, submission_content_node),
         {:ok, tool} <- Tools.create_survey_tool(tool_attrs, study, promotion, tool_content_node) do
      tool
    end
  end

  defp create_tool_attrs() do
    %{
      reward_currency: :eur,
      devices: [:phone, :tablet, :desktop]
    }
  end

  defp create_promotion_attrs(title, user, profile) do
    image_id = image_catalog().random(:abstract)

    %{
      title: title,
      marks: ["vu"],
      plugin: "survey",
      banner_photo_url: profile.photo_url,
      banner_title: user.displayname,
      banner_subtitle: profile.title,
      banner_url: profile.url,
      image_id: image_id
    }
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-survey", "title") }}
        menus={{ @menus }}
      >
        <ContentArea>
          <MarginY id={{:page_top}} />
          <Case value={{ Enum.count(@surveys) > 0 }} >
          <True>
            <div class="flex flex-row items-center">
              <div class="h-full">
                <Title2 margin="">{{ dgettext("link-survey", "survey.overview.title") }}</Title2>
              </div>
              <div class="flex-grow">
              </div>
              <div class="h-full pt-2px lg:pt-1">
                <Send vm={{ %{event: "create_tool" } }}>
                  <Forward vm={{ label: dgettext("link-survey", "add.new.button") }} />
                </Send>
              </div>
            </div>
            <MarginY id={{:title2_bottom}} />
            <DynamicGrid>
              <div :for={{ card <- @surveys  }} >
                <PrimaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :edit, id: card.edit_id } }} />
              </div>
            </DynamicGrid>
            <Spacing value="L" />
          </True>
          <False>
            <Empty
              title={{ dgettext("link-survey", "empty.title") }}
              body={{ dgettext("link-survey", "empty.description") }}
              illustration="cards"
            />
            <Spacing value="L" />
            <PrimaryLiveViewButton label={{ dgettext("link-survey", "add.first.button") }} event="create_tool"/>
          </False>
          </Case>
        </ContentArea>
      </Workspace>
    """
  end
end
