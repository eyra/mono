defmodule Systems.Assignment.InfoForm do
  use CoreWeb.LiveForm, :fabric
  use Fabric.LiveComponent
  use CoreWeb.FileUploader, ~w(.png .jpg .jpeg .svg)

  import Core.ImageCatalog, only: [image_catalog: 0]
  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Text
  alias Core.ImageHelpers
  alias Frameworks.Pixel.Image
  alias CoreWeb.UI.ImageCatalogPicker

  alias Systems.Assignment

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        {local_relative_path, _local_full_path, _remote_file}
      ) do
    save(socket, entity, :auto_save, %{logo_url: local_relative_path})
  end

  @impl true
  def update(
        %{id: id, entity: entity, viewport: viewport, breakpoint: breakpoint},
        socket
      ) do
    changeset = Assignment.InfoModel.changeset(entity, :create, %{})

    {
      :ok,
      socket
      |> assign(
        id: id,
        entity: entity,
        changeset: changeset,
        viewport: viewport,
        breakpoint: breakpoint
      )
      |> update_image_info()
      |> update_image_picker_button()
      |> init_file_uploader(:photo)
    }
  end

  @impl true
  def compose(:image_picker, %{
        entity: %{title: title},
        viewport: viewport,
        breakpoint: breakpoint
      }) do
    %{
      module: ImageCatalogPicker,
      params: %{
        viewport: viewport,
        breakpoint: breakpoint,
        static_path: &CoreWeb.Endpoint.static_path/1,
        initial_query: title,
        image_catalog: image_catalog()
      }
    }
  end

  defp update_image_info(%{assigns: %{entity: %{image_id: image_id}}} = socket) do
    image_info = ImageHelpers.get_image_info(image_id, 400, 300)
    socket |> assign(image_info: image_info)
  end

  defp update_image_picker_button(%{assigns: %{myself: myself}} = socket) do
    image_picker_button = %{
      action: %{type: :send, event: "open_image_picker", target: myself},
      face: %{
        type: :secondary,
        text_color: "text-primary",
        label: dgettext("eyra-assignment", "search.different.image.button")
      }
    }

    socket |> assign(image_picker_button: image_picker_button)
  end

  # Handle Events

  @impl true
  def handle_event("open_image_picker", _, socket) do
    {
      :noreply,
      socket
      |> compose_child(:image_picker)
      |> show_popup(:image_picker)
    }
  end

  @impl true
  def handle_event(
        "finish",
        %{image_id: _image_id} = attrs,
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
      |> update_image_info()
      |> hide_popup(:image_picker)
    }
  end

  @impl true
  def handle_event("finish", _, socket) do
    {:noreply, socket |> hide_popup(:image_picker)}
  end

  @impl true
  def handle_event("save", %{"info_model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, :auto_save, attrs)
    }
  end

  # Saving

  def save(socket, entity, type, attrs) do
    changeset = Assignment.InfoModel.changeset(entity, type, attrs)

    socket
    |> save(changeset)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
        <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself} >
          <Text.title3><%= dgettext("eyra-assignment", "settings.branding.title") %></Text.title3>
          <Text.body><%= dgettext("eyra-assignment", "settings.branding.text") %></Text.body>
          <.spacing value="M" />
          <.text_input form={form} field={:title} label_text={dgettext("eyra-assignment", "settings.title.label")} />
          <.text_input form={form} field={:subtitle} label_text={dgettext("eyra-assignment", "settings.subtitle.label")} />
          <.spacing value="S" />
          <Text.title5 align="text-left"><%= dgettext("eyra-assignment", "settings.logo.title") %></Text.title5>
          <.spacing value="XS" />
          <.photo_input
            static_path={&CoreWeb.Endpoint.static_path/1}
            photo_url={@entity.logo_url}
            uploads={@uploads}
            primary_button_text={dgettext("eyra-assignment", "choose.logo.file")}
            secondary_button_text={dgettext("eyra-assignment", "choose.other.logo.file")}
            placeholder="logo_placeholder"
          />
          <.spacing value="L" />
          <Text.title5 align="text-left"><%= dgettext("eyra-assignment", "settings.image.title") %></Text.title5>
          <.spacing value="XS" />
          <div class="flex flex-row gap-4">
            <Image.preview image_url={@image_info.url} placeholder="" />
            <Button.dynamic {@image_picker_button} />
          </div>
        </.form>
    </div>
    """
  end
end
