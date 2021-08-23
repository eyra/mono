defmodule CoreWeb.Promotion.Form do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader

  alias Core.Enums.Themes
  alias Core.Promotions
  alias Core.Promotions.Promotion

  alias CoreWeb.Router.Helpers, as: Routes

  alias EyraUI.Text.{Title2, Title3, BodyMedium}
  alias EyraUI.Form.{Form, TextInput, TextArea, PhotoInput, UrlInput}
  alias EyraUI.Selector.Selector
  alias EyraUI.ImagePreview
  alias EyraUI.Button.SecondaryAlpineButton

  prop(props, :any, required: true)

  data(entity, :any)
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
    |> save(entity, %{banner_photo_url: uploaded_file})
  end

  def update(%{image_id: image_id}, %{assigns: %{entity: entity}} = socket) do
    attrs = %{image_id: image_id}
    image_url = Promotion.get_image_url(attrs, %{width: 400, height: 300})

    {
      :ok,
      socket
      |> assign(image_url: image_url)
      |> save(entity, attrs)
    }
  end

  # Handle Selector Update
  def update(
        %{active_item_ids: active_item_ids, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    {:ok, socket |> save(entity, %{selector_id => active_item_ids})}
  end

  # Handle update from parent after auto-save, prevents overwrite of current state
  def update(_params, %{assigns: %{entity: _entity}} = socket) do
    {
      :ok,
      socket
    }
  end

  def update(%{id: id, props: %{entity_id: entity_id}}, socket) do
    entity = Promotions.get!(entity_id)
    changeset = Promotion.changeset(entity, :create, %{})

    byline = Promotion.get_byline(entity)
    image_url = Promotion.get_image_url(entity, %{width: 400, height: 300})
    theme_labels = Themes.labels(entity.themes)

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
    }
  end

  # Save
  def save(socket, %Promotion{} = entity, attrs) do
    changeset = Promotion.changeset(entity, :save, attrs)

    socket
    |> schedule_save(changeset)
  end

  # Handle Events

  def handle_event("save", %{"promotion" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, attrs)
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Title2>{{dgettext("eyra-promotion", "form.title")}}</Title2>
        <Form id={{@id}} changeset={{@changeset}} change_event="save" focus={{@focus}} target={{@myself}}>
          <TextInput field={{:title}} label_text={{dgettext("eyra-promotion", "title.label")}} target={{@myself}} />
          <TextInput field={{:subtitle}} label_text={{dgettext("eyra-promotion", "subtitle.label")}} target={{@myself}} />

          <Spacing value="XL" />
          <Title3>{{dgettext("eyra-promotion", "themes.title")}}</Title3>
          <BodyMedium>{{dgettext("eyra-promotion", "themes.label")}}</BodyMedium>
          <Spacing value="XS" />
          <Selector id={{:themes}} items={{ @theme_labels }} parent={{ %{type: __MODULE__, id: @id} }} />
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-promotion", "image.title")}}</Title3>
          <BodyMedium>{{dgettext("eyra-promotion", "image.label")}}</BodyMedium>
          <Spacing value="XS" />
          <div class="flex flex-row">
            <ImagePreview image_url={{ @image_url }} placeholder="" />
            <Spacing value="S" direction="l" />
            <div class="flex-wrap">
              <SecondaryAlpineButton click="$parent.$parent.open = true, $parent.$parent.$parent.$parent.overlay = true" label={{dgettext("eyra-promotion", "search.different.image.button")}} />
            </div>
          </div>
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-promotion", "expectations.title")}}</Title3>
          <TextArea field={{:expectations}} label_text={{dgettext("eyra-promotion", "expectations.label")}} target={{@myself}}/>
          <Spacing value="L" />

          <Title3>{{dgettext("eyra-promotion", "description.title")}}</Title3>
          <TextArea field={{:description}} label_text={{dgettext("eyra-promotion", "description.label")}} target={{@myself}}/>
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

          <TextInput field={{:banner_title}} label_text={{dgettext("eyra-promotion", "banner.title.label")}} target={{@myself}} />
          <TextInput field={{:banner_subtitle}} label_text={{dgettext("eyra-promotion", "banner.subtitle.label")}} target={{@myself}} />
          <UrlInput field={{:banner_url}} label_text={{dgettext("eyra-promotion", "banner.url.label")}} target={{@myself}} />
        </Form>
      </ContentArea>
    """
  end
end
