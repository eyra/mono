defmodule CoreWeb.Promotion.Form do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader

  alias Core.Promotions
  alias Core.Promotions.Promotion

  alias CoreWeb.Router.Helpers, as: Routes

  alias EyraUI.Text.{Title2, Title3, Body, BodyLarge}
  alias EyraUI.Form.{Form, TextInput, TextArea, PhotoInput, UrlInput}
  alias EyraUI.Selector.Selector
  alias EyraUI.ImagePreview
  alias EyraUI.Button.SecondaryAlpineButton

  prop(props, :any, required: true)

  data(entity, :any)
  data(validate?, :boolean)
  data(changeset, :any)
  data(uploads, :any)
  data(focus, :any, default: "")

  data(published?, :boolean)
  data(byline, :string)
  data(image_url, :string)
  data(theme_labels, :list)

  @impl true
  def save_file(%{assigns: %{entity: entity}} = socket, uploaded_file) do
    socket
    # force save
    |> save(entity, %{banner_photo_url: uploaded_file}, false)
  end

  def update(%{image_id: image_id}, %{assigns: %{entity: entity}} = socket) do
    attrs = %{image_id: image_id}
    image_url = Promotion.get_image_url(attrs, %{width: 400, height: 300})

    {
      :ok,
      socket
      |> assign(image_url: image_url)
      # force save
      |> save(entity, attrs, false)
    }
  end

  # Handle Selector Update
  def update(
        %{active_item_ids: active_theme_ids, selector_id: :themes},
        %{assigns: %{entity: entity}} = socket
      ) do
    active_theme_ids =
      active_theme_ids
      |> Enum.map(&Atom.to_string(&1))

    {
      :ok,
      socket
      # force save
      |> save(entity, %{:themes => active_theme_ids}, false)
    }
  end

  # Handle update from parent after attempt to publish
  def update(%{props: %{validate?: new}}, %{assigns: %{validate?: current}} = socket)
      when new != current do
    {
      :ok,
      socket
      |> assign(validate?: new)
      |> validate_for_publish()
    }
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{entity: _entity}} = socket) do
    {:ok, socket}
  end

  def update(
        %{
          id: id,
          props: %{entity_id: entity_id, validate?: validate?, themes_module: themes_module}
        },
        socket
      ) do
    entity = Promotions.get!(entity_id)
    changeset = Promotion.changeset(entity, :create, %{})

    byline = Promotion.get_byline(entity)
    image_url = Promotion.get_image_url(entity, %{width: 400, height: 300})
    theme_labels = themes_module.labels(entity.themes)

    {
      :ok,
      socket
      |> init_file_uploader(:photo)
      |> assign(id: id)
      |> assign(entity_id: entity_id)
      |> assign(entity: entity)
      |> assign(changeset: changeset)
      |> assign(byline: byline)
      |> assign(image_url: image_url)
      |> assign(theme_labels: theme_labels)
      |> assign(validate?: validate?)
      |> validate_for_publish()
    }
  end

  # Save
  defp save(socket, %Promotion{} = entity, attrs, schedule?) do
    changeset = Promotion.changeset(entity, :save, attrs)

    socket
    |> save(changeset, schedule?)
    |> validate_for_publish()
  end

  # Validate

  def validate_for_publish(%{assigns: %{id: id, entity: entity, validate?: true}} = socket) do
    changeset =
      Promotion.operational_changeset(entity, %{})
      |> Map.put(:action, :validate_for_publish)

    send(self(), %{id: id, ready?: changeset.valid?})

    socket
    |> assign(changeset: changeset)
  end

  def validate_for_publish(socket), do: socket

  # Handle Events

  @impl true
  def handle_event("save", %{"promotion" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs, true)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Title2>{{dgettext("eyra-promotion", "form.title")}}</Title2>
        <BodyLarge>{{dgettext("eyra-promotion", "form.description")}}</BodyLarge>
        <Spacing value="M" />
        <Form id={{@id}} changeset={{@changeset}} change_event="save" focus={{@focus}} target={{@myself}}>
          <TextInput field={{:title}} label_text={{dgettext("eyra-promotion", "title.label")}} />
          <TextInput field={{:subtitle}} label_text={{dgettext("eyra-promotion", "subtitle.label")}} />

          <Spacing value="XL" />
          <Title3>{{dgettext("eyra-promotion", "themes.title")}}</Title3>
          <Body>{{dgettext("eyra-promotion", "themes.label")}}</Body>
          <Spacing value="XS" />
          <Selector id={{:themes}} items={{ @theme_labels }} parent={{ %{type: __MODULE__, id: @id} }} />
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-promotion", "image.title")}}</Title3>
          <Body>{{dgettext("eyra-promotion", "image.label")}}</Body>
          <Spacing value="XS" />
          <div class="flex flex-row">
            <ImagePreview image_url={{ @image_url }} placeholder="" />
            <Spacing value="S" direction="l" />
            <div class="flex-wrap">
              <SecondaryAlpineButton click="$parent.image_picker = true, $parent.$parent.$parent.overlay = true" label={{dgettext("eyra-promotion", "search.different.image.button")}} />
            </div>
          </div>
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-promotion", "expectations.title")}}</Title3>
          <TextArea field={{:expectations}} label_text={{dgettext("eyra-promotion", "expectations.label")}} />
          <Spacing value="L" />

          <Title3>{{dgettext("eyra-promotion", "description.title")}}</Title3>
          <TextArea field={{:description}} label_text={{dgettext("eyra-promotion", "description.label")}} />
          <Spacing value="L" />

          <Title3>{{dgettext("eyra-promotion", "banner.title")}}</Title3>
          <PhotoInput
            conn={{@socket}}
            static_path={{&Routes.static_path/2}}
            photo_url={{@entity.banner_photo_url}}
            uploads={{@uploads}}
            primary_button_text={{dgettext("eyra-promotion", "choose.banner.photo.file")}}
            secondary_button_text={{dgettext("eyra-promotion", "choose.other.banner.photo.file")}}
            />

          <Spacing value="S" />

          <TextInput field={{:banner_title}} label_text={{dgettext("eyra-promotion", "banner.title.label")}} />
          <TextInput field={{:banner_subtitle}} label_text={{dgettext("eyra-promotion", "banner.subtitle.label")}} />
          <UrlInput field={{:banner_url}} label_text={{dgettext("eyra-promotion", "banner.url.label")}} />
        </Form>
      </ContentArea>
    """
  end
end
