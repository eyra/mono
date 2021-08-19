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

  data(surveys, :map, default: [])

  def mount(_params, _session, socket) do
    {:ok, socket |> update_menus()}
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def handle_event("create_tool", _params, socket) do
    tool = create_tool(socket)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, Link.Survey.Content, tool.id))}
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
    image_id = List.first(Core.ImageCatalog.Unsplash.random(1))
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
            <PrimaryLiveViewButton label={{ dgettext("link-survey", "add.new.button") }} event="create_tool"/>
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
