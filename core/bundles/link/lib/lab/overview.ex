defmodule Link.LabStudy.Overview do
  @moduledoc """
   The Lab studies overview screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :labstudies

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias Frameworks.Pixel.Button.PrimaryLiveViewButton

  data(labstudies, :map, default: [])

  def mount(_params, _session, socket) do
    {:ok, socket |> update_menus()}
  end

  def handle_auto_save_done(socket) do
    socket |> update_menus()
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-labstudies", "title") }}
        menus={{ @menus }}
      >
        <ContentArea>
          <MarginY id={{:page_top}} />
          <Case value={{ Enum.count(@labstudies) > 0 }} >
            <True>
              <PrimaryLiveViewButton label={{ dgettext("link-labstudies", "add.new.button") }} event="create_tool"/>
            </True>
            <False>
              <Empty
                title={{ dgettext("link-labstudies", "empty.title") }}
                body={{ dgettext("link-labstudies", "empty.description") }}
                illustration="cards"
              />
              <Spacing value="L" />
              <PrimaryLiveViewButton label={{ dgettext("link-labstudies", "add.first.button") }} event="create_tool"/>
            </False>
          </Case>
        </ContentArea>
      </Workspace>
    """
  end
end
