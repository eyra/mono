defmodule Link.Marketplace do
  @moduledoc """
  The home screen.
  """
  use CoreWeb, :live_view

  alias Core.Studies
  alias Core.Studies.Study
  alias Core.Survey.Tool, as: SurveyTool
  alias Core.Lab.Tool, as: LabTool
  alias Core.Lab.Tools
  alias Core.Accounts
  alias Core.Content
  alias Core.Promotions

  alias Link.Marketplace.Card, as: CardVM

  alias EyraUI.Card.{PrimaryStudy, SecondaryStudy}
  alias EyraUI.Container.{ContentArea}
  alias EyraUI.Text.{Title2}
  alias EyraUI.Grid.{DynamicGrid}

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  data(highlighted_count, :any)
  data(owned_studies, :any)
  data(subject_studies, :any)
  data(available_studies, :any)
  data(available_count, :any)
  data(current_user, :any)

  def mount(_params, _session, socket) do
    user = socket.assigns[:current_user]
    preload = [survey_tool: [:promotion], lab_tool: [:promotion, :time_slots]]

    subject_studies =
      user
      |> Studies.list_subject_studies(preload: preload)
      |> Enum.map(&CardVM.primary_study(&1, socket))

    highlighted_studies = subject_studies
    highlighted_count = Enum.count(subject_studies)

    exclusion_list =
      highlighted_studies
      |> Stream.map(fn study -> study.id end)
      |> Enum.into(MapSet.new())

    available_studies =
      Studies.list_studies_with_published_promotion([LabTool, SurveyTool],
        exclude: exclusion_list,
        preload: preload
      )
      |> Enum.map(&CardVM.primary_study(&1, socket))

    available_count = Enum.count(available_studies)

    socket =
      socket
      |> assign(highlighted_count: highlighted_count)
      |> assign(subject_studies: subject_studies)
      |> assign(available_studies: available_studies)
      |> assign(available_count: available_count)

    {:ok, socket}
  end

  def handle_info({:card_click, %{action: :edit, id: id}}, socket) do
    {:noreply,
     push_redirect(socket, to: CoreWeb.Router.Helpers.live_path(socket, Link.Survey.Content, id))}
  end

  def handle_info({:card_click, %{action: :public, id: id}}, socket) do
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Promotion.Public, id))}
  end

  def handle_event("create_tool", _params, socket) do
    tool = create_tool(socket)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Link.Survey.Content, tool.id))}
  end

  def handle_event("menu-item-clicked", %{"action" => action}, socket) do
    # toggle menu
    {:noreply, push_redirect(socket, to: action)}
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

    with {:ok, study} <- Studies.create_study(changeset, user),
         {:ok, _author} <- Studies.add_author(study, user),
         {:ok, tool_content_node} <- Content.Nodes.create(%{ready: false}),
         {:ok, promotion_content_node} <-
           Content.Nodes.create(%{ready: false}, tool_content_node),
         {:ok, promotion} <- Promotions.create(promotion_attrs, study, promotion_content_node),
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
    %{
      title: title,
      marks: ["vu"],
      plugin: "survey",
      banner_photo_url: profile.photo_url,
      banner_title: user.displayname,
      banner_subtitle: profile.title,
      banner_url: profile.url
    }
  end

  def render(assigns) do
    ~H"""
        <Workspace
          title={{ dgettext("eyra-ui", "marketplace.title") }}
          user={{@current_user}}
          user_agent={{ Browser.Ua.to_ua(@socket) }}
          active_item={{ :marketplace }}
        >
          <ContentArea>
            <Title2>
              {{ dgettext("eyra-study", "study.highlighted.title") }}
              <span class="text-primary"> {{ @highlighted_count }}</span>
            </Title2>
            <DynamicGrid>
              <div :for={{ card <- @subject_studies  }} >
                <PrimaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :public, id: card.open_id } }} />
              </div>
            </DynamicGrid>
            <div class="mt-12 lg:mt-16"/>
            <Title2>
              {{ dgettext("eyra-study", "study.all.title") }}
              <span class="text-primary"> {{ @available_count }}</span>
            </Title2>
            <DynamicGrid>
              <div :for={{ card <- @available_studies  }} class="mb-1" >
                <SecondaryStudy conn={{@socket}} path_provider={{Routes}} card={{card}} click_event_data={{%{action: :public, id: card.open_id } }} />
              </div>
            </DynamicGrid>
          </ContentArea>
        </Workspace>
    """
  end
end
