defmodule Link.LabStudy.Overview do
  @moduledoc """
   The Lab studies overview screen.
  """
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Workspace.Component, :labstudies

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias EyraUI.Container.ContentArea

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
          <div>TBD</div>
        </ContentArea>
      </Workspace>
    """
  end
end
