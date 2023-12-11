defmodule Systems.Content.PageForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent

  alias Systems.Content

  @impl true
  def update(%{id: id, entity: nil}, socket) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: nil,
        visible: false,
        changeset: nil
      )
    }
  end

  @impl true
  def update(%{id: id, entity: entity}, socket) do
    changeset = Content.PageModel.changeset(entity, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        visible: true,
        changeset: changeset
      )
    }
  end

  @impl true
  def handle_event(
        "save",
        %{"page_model[body]_input" => body},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> save(entity, %{body: body})
    }
  end

  # Saving

  def save(socket, entity, attrs) do
    changeset = Content.PageModel.changeset(entity, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <.form id={"#{@id}_agreement_form"} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
          <%!-- <%= if @visible do %>
            <.text_input form={form} field={:title} label_text={dgettext("eyra-content", "page_form.title.label")} visible={@visible} />
            <Text.form_field_label id={:template_label}>
              <%= dgettext("eyra-content", "page_form.body.label") %>
            </Text.form_field_label>
            <.spacing value="XXS" />
          <% end %> --%>
          <!-- always render wyiwyg te prevent scrollbar reset in LiveView -->
          <.wysiwyg_area form={form} field={:body} visible={@visible}/>
        </.form>
      </div>
    """
  end
end
