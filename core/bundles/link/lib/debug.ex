defmodule Link.Debug do
  @moduledoc """
  The dashboard screen.
  """
  use CoreWeb, :live_view

  alias CoreWeb.Layouts.Workspace.Component, as: Workspace

  alias EyraUI.Button.Action.Redirect
  alias EyraUI.Button.Face.Primary

  alias EyraUI.Container.{ContentArea, Wrap}

  def mount(_params, _session, socket) do
    require_feature(:debug)
    {:ok, socket }
  end

  def render(assigns) do
    ~H"""
      <Workspace
        title={{ dgettext("link-ui", "debug.title") }}
        user={{@current_user}}
        user_agent={{ Browser.Ua.to_ua(@socket) }}
        active_item={{ :debug }}
      >
        <ContentArea>
        <Wrap>
          <Redirect to={{ Routes.live_path(@socket, Link.Onboarding.Wizard) }}>
            <Primary label="Start onboarding flow" />
          </Redirect>
        </Wrap>
        </ContentArea>
      </Workspace>
    """
  end
end
