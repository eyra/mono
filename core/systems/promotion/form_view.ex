defmodule Systems.Promotion.FormView do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader, accept: ~w(.png .jpg .jpeg)

  import Frameworks.Pixel.Form

  alias Core.ImageHelpers
  alias Frameworks.Pixel.Text
  alias Systems.Promotion
  alias Systems.Promotion.WysiwygForm

  @impl true
  def process_file(%{assigns: %{entity: entity}} = socket, %{public_url: public_url}) do
    save(socket, entity, %{banner_photo_url: public_url})
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
  def update(%{id: id, entity: entity}, socket) do
    {
      :ok,
      socket
      |> init_file_uploader(:photo)
      |> assign(
        id: id,
        entity: entity
      )
      |> update_changeset()
      |> update_image_info()
      |> update_image_picker_button()
      |> validate_for_publish()
      |> compose_child(:expectations_form)
      |> compose_child(:description_form)
      |> compose_child(:prerequisites_form)
    }
  end

  defp update_changeset(%{assigns: %{entity: entity}} = socket) do
    changeset = Promotion.Model.changeset(entity, :create, %{})
    assign(socket, changeset: changeset, form: to_form(changeset))
  end

  defp update_image_info(%{assigns: %{entity: %{image_id: image_id}}} = socket) do
    image_info = ImageHelpers.get_image_info(image_id, 400, 300)
    assign(socket, image_info: image_info)
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

    assign(socket, image_picker_button: image_picker_button)
  end

  # Save
  defp save(socket, %Promotion.Model{} = entity, attrs) do
    changeset = Promotion.Model.changeset(entity, :save, attrs)

    socket
    |> save(changeset)
    |> validate_for_publish()
  end

  # Validate
  def validate_for_publish(%{assigns: %{entity: entity}} = socket) do
    changeset =
      entity
      |> Promotion.Model.operational_changeset(%{})
      |> Map.put(:action, :validate_for_publish)

    assign(socket, changeset: changeset, form: to_form(changeset))
  end

  @impl true
  def compose(:expectations_form, %{entity: entity}) do
    %{
      module: WysiwygForm,
      params: %{
        field_name: :expectations,
        entity: entity,
        label_text: dgettext("eyra-promotion", "expectations.placeholder"),
        min_height: "min-h-[122px]",
        max_height: "max-h-[512px]",
        reserve_error_space: false
      }
    }
  end

  @impl true
  def compose(:description_form, %{entity: entity}) do
    %{
      module: WysiwygForm,
      params: %{
        field_name: :description,
        entity: entity,
        label_text: dgettext("eyra-promotion", "background.placeholder"),
        min_height: "min-h-[122px]",
        max_height: "max-h-[512px]",
        reserve_error_space: false
      }
    }
  end

  @impl true
  def compose(:prerequisites_form, %{entity: entity}) do
    %{
      module: WysiwygForm,
      params: %{
        field_name: :prerequisites,
        entity: entity,
        label_text: dgettext("eyra-promotion", "prerequisites.placeholder"),
        min_height: "min-h-[122px]",
        max_height: "max-h-[512px]",
        reserve_error_space: false
      }
    }
  end

  # Events
  @impl true
  def handle_event("save", %{"model" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      save(socket, entity, attrs)
    }
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: themes, source: %{name: :themes}},
        %{assigns: %{entity: entity}} = socket
      ) do
    {
      :noreply,
      save(socket, entity, %{:themes => Enum.map(themes, &Atom.to_string(&1))})
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form id={"top_#{@id}"} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
        <.text_input form={form} field={:title} label_text={dgettext("eyra-promotion", "title.label")} />
        <.text_input form={form} field={:subtitle} label_text={dgettext("eyra-promotion", "subtitle.label")} />

        <.spacing value="XL" />
      </.form>

      <Text.title3><%= dgettext("eyra-promotion", "copy.title") %></Text.title3>
      <.spacing value="XS" />
      <.child name={:prerequisites_form} fabric={@fabric} />
      <.spacing value="XS" />

      <.child name={:expectations_form} fabric={@fabric} />
      <.spacing value="XS" />

      <.child name={:description_form} fabric={@fabric} />
      <.spacing value="XS" />

      <.spacing value="L" />

      <.form id={"bottom_#{@id}"} :let={form} for={@changeset} phx-change="save" phx-target={@myself}>
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
