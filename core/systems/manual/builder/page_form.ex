defmodule Systems.Manual.Builder.PageForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.WysiwygAreaHelpers
  use CoreWeb.FileUploader, accept: ~w(.png .jpg .jpeg)

  alias Systems.Manual

  @impl true
  def update(%{page: page}, socket) do
    {
      :ok,
      socket
      |> assign(entity: page)
      |> update_changeset()
      |> update_wysiwyg_form()
      |> init_file_uploader(:image)
    }
  end

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        {_path, image_url, _original_filename}
      ) do
    changeset = Manual.PageModel.changeset(entity, %{image: image_url})

    socket
    |> save(changeset)
  end

  def update_changeset(%{assigns: %{entity: entity}} = socket) do
    changeset = Manual.PageModel.changeset(entity, %{})
    socket |> assign(changeset: changeset)
  end

  def update_wysiwyg_form(%{assigns: %{entity: %{text: text}}} = socket) do
    wysiwyg_form = to_form(%{"text" => text})
    socket |> assign(wysiwyg_form: wysiwyg_form)
  end

  def update_wysiwyg_form(socket) do
    wysiwyg_form = to_form(%{"text" => nil})
    socket |> assign(text_form: wysiwyg_form)
  end

  @impl true
  def handle_wysiwyg_update(%{assigns: %{entity: entity, text: text}} = socket) do
    changeset = Manual.PageModel.changeset(entity, %{text: text})

    socket
    |> save(changeset)
  end

  @impl true
  def handle_event("save", %{"page_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    changeset = Manual.PageModel.changeset(entity, attrs)

    {
      :noreply,
      socket
      |> save(changeset)
    }
  end

  @impl true
  def render(assigns) do
    # Render wysiwyg in a separate form to enable `save_wysiwyg` event. See: `Frameworks.Pixel.WysiwygAreaHelpers`
    ~H"""
    <div>
      <.form id={"#{@id}_title_form"} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
        <.spacing value="M" />
        <.image_input
            static_path={&CoreWeb.Endpoint.static_path/1}
            image_url={@entity.image}
            uploads={@uploads}
            primary_button_text={dgettext("eyra-manual", "choose.image.file")}
            secondary_button_text={dgettext("eyra-manual", "choose.other.image.file")}
          />
        <.spacing value="M" />
        <.text_input
          form={form}
          field={:title}
          label_text={dgettext("eyra-manual", "page.title.label")}
        />
      </.form>
      <.form id={"#{@id}_wysiwyg_form"} :let={form} for={@wysiwyg_form} phx-change="save_wysiwyg" phx-target={@myself} >
        <.wysiwyg_area
          form={form}
          field={:text}
          label_text={dgettext("eyra-manual", "page.text.label")}
          min_height="min-h-[122px]"
          max_height="max-h-[512px]"
          reserve_error_space={false}
        />
      </.form>
    </div>
    """
  end
end
