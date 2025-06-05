defmodule Systems.Promotion.FormView do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, accept: ~w(.png .jpg .jpeg)
  use Frameworks.Pixel.WysiwygAreaHelpers

  alias Systems.{
    Promotion
  }

  alias Core.ImageHelpers

  import Frameworks.Pixel.Form

  alias Frameworks.Pixel.Text
  import Frameworks.Pixel.Form
  alias Frameworks.Pixel.Selector

  @impl true
  def process_file(
        %{assigns: %{entity: entity}} = socket,
        {_path, url, _original_filename}
      ) do
    socket
    |> save(entity, %{banner_photo_url: url})
  end

  @impl true
  def update(%{image_id: image_id}, %{assigns: %{entity: entity}} = socket) do
    attrs = %{image_id: image_id}
    image_info = ImageHelpers.get_image_info(image_id, 400, 300)

    {
      :ok,
      socket
      |> assign(image_info: image_info)
      |> save(entity, attrs)
    }
  end

  @impl true
  def update(
        %{
          id: id,
          entity: entity,
          themes_module: themes_module
        },
        socket
      ) do
    {
      :ok,
      socket
      |> init_file_uploader(:photo)
      |> assign(
        id: id,
        entity: entity,
        themes_module: themes_module
      )
      |> update_changeset()
      |> update_image_info()
      |> update_image_picker_button()
      |> update_theme_labels()
      |> update_wysiwyg_form()
      |> compose_child(:themes)
      |> validate_for_publish()
    }
  end

  @impl true
  def compose(:themes, %{theme_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :label
      }
    }
  end

  defp update_changeset(%{assigns: %{entity: entity}} = socket) do
    changeset = Promotion.Model.changeset(entity, :create, %{})
    socket |> assign(changeset: changeset, form: to_form(changeset))
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
        label: dgettext("eyra-promotion", "search.different.image.button")
      }
    }

    socket |> assign(image_picker_button: image_picker_button)
  end

  defp update_theme_labels(
         %{assigns: %{entity: %{themes: themes}, themes_module: themes_module}} = socket
       ) do
    theme_labels = themes_module.labels(themes)
    socket |> assign(theme_labels: theme_labels)
  end

  # Save
  defp save(socket, %Promotion.Model{} = entity, attrs) do
    changeset = Promotion.Model.changeset(entity, :save, attrs)

    socket
    |> save(changeset)
    |> update_theme_labels()
    |> validate_for_publish()
  end

  # Validate

  def validate_for_publish(%{assigns: %{entity: entity}} = socket) do
    changeset =
      Promotion.Model.operational_changeset(entity, %{})
      |> Map.put(:action, :validate_for_publish)

    socket
    |> assign(changeset: changeset, form: to_form(changeset))
  end

  defp initial_image_query(%{assigns: %{entity: entity}}) do
    case entity.themes do
      nil -> ""
      themes -> themes |> Enum.join(" ")
    end
  end

  def update_wysiwyg_form(
        %{assigns: %{entity: %{expectations: expectations, description: description}}} = socket
      ) do
    wysiwyg_form =
      to_form(%{
        "expectations" => expectations || "",
        "description" => description || ""
      })

    socket |> assign(wysiwyg_form: wysiwyg_form)
  end

  @impl true
  def handle_wysiwyg_update(
        %{assigns: %{expectations: expectations, description: description, entity: entity}} =
          socket
      )
      when not is_nil(expectations) and not is_nil(description) do
    attributes = %{expectations: expectations, description: description}
    changeset = Promotion.Model.changeset(entity, :save, attributes)
    save(socket, changeset)
  end

  def handle_wysiwyg_update(%{assigns: %{expectations: expectations, entity: entity}} = socket)
      when not is_nil(expectations) do
    attributes = %{expectations: expectations}
    changeset = Promotion.Model.changeset(entity, :save, attributes)
    save(socket, changeset)
  end

  def handle_wysiwyg_update(%{assigns: %{description: description, entity: entity}} = socket)
      when not is_nil(description) do
    attributes = %{description: description}
    changeset = Promotion.Model.changeset(entity, :save, attributes)
    save(socket, changeset)
  end

  # Events

  @impl true
  def handle_event("save", %{"model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  def handle_event("open_image_picker", _, socket) do
    send(self(), {:show_image_picker, initial_image_query(socket)})
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: themes, source: %{name: :themes}},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      socket
      |> save(entity, %{:themes => Enum.map(themes, &Atom.to_string(&1))})
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
        <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
          <.text_input form={form} field={:title} label_text={dgettext("eyra-promotion", "title.label")} />
          <.text_input form={form} field={:subtitle} label_text={dgettext("eyra-promotion", "subtitle.label")} />

          <.spacing value="L" />
          <Text.title3><%= dgettext("eyra-promotion", "themes.title") %></Text.title3>
          <Text.body><%= dgettext("eyra-promotion", "themes.label") %></Text.body>
          <.spacing value="XS" />
          <.child name={:themes} fabric={@fabric} />
          <.spacing value="XL" />
        </.form>


          <Text.title3><%= dgettext("eyra-promotion", "copy.title") %></Text.title3>

          <.form id={"#{@id}_wysiwyg_form_expectations"} :let={form} for={@wysiwyg_form} phx-change="save_wysiwyg" phx-target={@myself} >
            <.wysiwyg_area
              form={form}
              field={:expectations}
              label_text={dgettext("eyra-promotion", "expectations.placeholder")}
              min_height="min-h-[122px]"
              max_height="max-h-[512px]"
              reserve_error_space={false}
            />
          </.form>
          <.spacing value="XS" />


          <.form id={"#{@id}_wysiwyg_form_description"} :let={form} for={@wysiwyg_form} phx-change="save_wysiwyg" phx-target={@myself} >
            <.wysiwyg_area
              form={form}
              field={:description}
              label_text={dgettext("eyra-promotion", "background.placeholder")}
              min_height="min-h-[122px]"
              max_height="max-h-[512px]"
              reserve_error_space={false}
            />
          </.form>
          <.spacing value="L" />


        <.form id={@id} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
          <Text.title3><%= dgettext("eyra-promotion", "banner.title") %></Text.title3>
          <.photo_input
            static_path={&CoreWeb.Endpoint.static_path/1}
            photo_url={@entity.banner_photo_url}
            uploads={@uploads}
            primary_button_text={dgettext("eyra-promotion", "choose.banner.photo.file")}
            secondary_button_text={dgettext("eyra-promotion", "choose.other.banner.photo.file")}
          />

          <.spacing value="S" />

          <.text_input form={form} field={:banner_title} label_text={dgettext("eyra-promotion", "banner.title.label")} />
          <.text_input form={form}
            field={:banner_subtitle}
            label_text={dgettext("eyra-promotion", "banner.subtitle.label")}
          />
          <.url_input form={form} field={:banner_url} label_text={dgettext("eyra-promotion", "banner.url.label")} />
        </.form>

      </div>
    """
  end
end
