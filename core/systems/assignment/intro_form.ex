defmodule Systems.Assignment.IntroForm do
  use CoreWeb, :live_component_fabric
  use Fabric.LiveComponent

  alias Frameworks.Pixel
  alias Systems.Assignment
  alias Systems.Content

  @impl true
  def update(%{id: id, assignment: assignment}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        assignment: assignment
      )
      |> update_page_ref()
      |> compose_child(:switch)
      |> compose_child(:content_page_form)
    }
  end

  def update_page_ref(%{assigns: %{assignment: %{page_refs: page_refs}}} = socket) do
    page_ref = Enum.find(page_refs, &(&1.key == :assignment_intro))
    socket |> assign(page_ref: page_ref)
  end

  @impl true
  def compose(:switch, %{page_ref: page_ref}) do
    %{
      module: Pixel.Switch,
      params: %{
        opt_in?: false,
        on_text: dgettext("eyra-assignment", "intro_form.on.label"),
        off_text: dgettext("eyra-assignment", "intro_form.off.label"),
        status:
          if page_ref do
            :on
          else
            :off
          end
      }
    }
  end

  @impl true
  def compose(:content_page_form, %{page_ref: nil}) do
    %{
      module: Content.PageForm,
      params: %{
        entity: nil
      }
    }
  end

  @impl true
  def compose(:content_page_form, %{page_ref: %{page: page}}) do
    %{
      module: Content.PageForm,
      params: %{
        entity: page
      }
    }
  end

  @impl true
  def handle_event(
        "update",
        %{status: :on},
        %{assigns: %{assignment: assignment}} = socket
      ) do
    page_ref = Assignment.Public.create_page_ref(assignment, :assignment_intro)

    {
      :noreply,
      socket |> assign(page_ref: page_ref)
    }
  end

  @impl true
  def handle_event("update", %{status: :off}, %{assigns: %{page_ref: page_ref}} = socket) do
    {:ok, _} = Assignment.Public.delete_page_ref(page_ref)

    {
      :noreply,
      socket |> assign(page_ref: page_ref)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.child name={:switch} fabric={@fabric} />
        <.spacing value="S" />
        <.child name={:content_page_form} fabric={@fabric} />
      </div>
    """
  end
end
