defmodule Systems.Manual.Builder.PageForm do
  use CoreWeb.LiveForm
  use Frameworks.Pixel.WysiwygAreaHelpers
  use CoreWeb.FileUploader, accept: ~w(.png .jpg .jpeg)

  import Core.ImageHelpers, only: [image_from_path!: 1, encode_image_info: 2]

  alias Systems.Manual

  @impl true
  def update(%{page: page}, socket) do
    {
      :ok,
      socket
      |> assign(entity: page, upload_in_progress: false)
      |> update_changeset()
      |> update_image_url()
      |> update_wysiwyg_form()
      |> init_file_uploader(:image)
    }
  end

  def update_image_url(%{assigns: %{entity: %{image: "{" <> _ = image}}} = socket) do
    %{"url" => image_url} = Jason.decode!(image)
    socket |> assign(image_url: image_url)
  end

  def update_image_url(%{assigns: %{entity: %{image: image_url}}} = socket) do
    socket |> assign(image_url: image_url)
  end

  @impl true
  def pre_process_file(%{tmp_path: tmp_path, public_url: image_url}) do
    encoded_image_info =
      image_from_path!(tmp_path)
      |> encode_image_info(image_url)

    %{encoded_image_info: encoded_image_info}
  end

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        %{encoded_image_info: encoded_image_info}
      ) do
    changeset = Manual.PageModel.changeset(entity, %{image: encoded_image_info})

    socket
    |> assign(upload_in_progress: false)
    |> save(changeset)
    |> update_image_url()
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
  def handle_event("save", %{"_target" => ["image"]}, socket) do
    {
      :noreply,
      socket
      |> assign(upload_in_progress: true)
    }
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
      <.form id={"#{@id}_title_form"} :let={form} for={@changeset} phx-change="save" phx-submit="save" phx-target={@myself} >
        <.spacing value="M" />
        <.image_input
            static_path={&CoreWeb.Endpoint.static_path/1}
            image_url={@image_url}
            uploads={@uploads}
            primary_button_text={dgettext("eyra-manual", "choose.image.file")}
            secondary_button_text={dgettext("eyra-manual", "choose.other.image.file")}
            loading={@upload_in_progress}
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
