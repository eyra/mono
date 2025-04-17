defmodule Systems.Assignment.OnboardingView do
  use CoreWeb, :live_component

  alias Systems.Assignment
  alias Systems.Content
  alias Systems.Account

  @impl true
  def update(%{user: user, page_ref: page_ref, title: title}, socket) do
    {
      :ok,
      socket
      |> assign(
        page_ref: page_ref,
        title: title,
        user: user
      )
      |> compose_child(:content_page)
      |> compose_element(:continue_button)
    }
  end

  @impl true
  def compose(:content_page, %{page_ref: nil}), do: nil

  @impl true
  def compose(:content_page, %{title: title, page_ref: %Assignment.PageRefModel{page: page}}) do
    %{
      module: Content.PageView,
      params: %{
        title: title,
        page: page
      }
    }
  end

  def compose(:continue_button, %{myself: myself}) do
    %{
      action: %{type: :send, event: "continue", target: myself},
      face: %{
        type: :primary,
        label: dgettext("eyra-assignment", "onboarding.continue.button")
      }
    }
  end

  @impl true
  def handle_event(
        "continue",
        _payload,
        %{assigns: %{user: user, page_ref: %{key: key, assignment_id: assignment_id}}} = socket
      ) do
    Account.Public.mark_as_visited(user, {key, assignment_id})

    {
      :noreply,
      socket |> send_event(:parent, "continue")
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <Area.content>
          <Margin.y id={:page_top} />
          <.child name={:content_page} fabric={@fabric} />
          <.spacing value="M" />
          <.wrap>
            <Button.dynamic {@continue_button} />
          </.wrap>
        </Area.content>
      </div>
    """
  end
end
