defmodule Link.Survey.Overview do
  @moduledoc """
   The surveys screen.
  """
  use CoreWeb, :live_view

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace
  alias EyraUI.Container.ContentArea

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-survey", "title") }}
        user={{@current_user}}
        user_agent={{ Browser.Ua.to_ua(@socket) }}
        active_item={{ :surveys }}
      >
        <ContentArea>
          <div>TBD</div>
        </ContentArea>
      </Workspace>
    """
  end
end
