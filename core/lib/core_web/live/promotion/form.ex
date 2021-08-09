defmodule CoreWeb.Promotion.Form do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader

  import CoreWeb.Gettext

  alias Core.Enums.Themes
  alias Core.Promotions
  alias Core.Promotions.Promotion

  alias CoreWeb.Router.Helpers, as: Routes

  alias EyraUI.Spacing
  alias EyraUI.Case.{Case, True, False}
  alias EyraUI.Status.{Info, Warning}
  alias EyraUI.Text.{Title1, Title3, BodyMedium, SubHead}
  alias EyraUI.Form.{Form, TextInput, TextArea, PhotoInput, UrlInput}
  alias EyraUI.Container.{ContentArea, Bar, BarItem}
  alias EyraUI.Selectors.LabelSelector
  alias EyraUI.ImagePreview
  alias EyraUI.Button.{SecondaryAlpineButton, PrimaryLiveViewButton, SecondaryLiveViewButton}

  prop(entity_id, :any, required: true)

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

    {
      :ok,
      socket
      |> save(entity, attrs)
    }
  end

  def update(_params, %{assigns: %{entity: _entity}} = socket) do
    {
      :ok,
      socket
    }
  end

  def update(%{id: id, entity_id: entity_id}, socket) do
    entity = Promotions.get!(entity_id)
    changeset = Promotion.changeset(entity, :create, %{})

    published? = Promotion.published?(entity)
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
      |> assign(published?: published?)
      |> assign(byline: byline)
      |> assign(image_url: image_url)
      |> assign(theme_labels: theme_labels)
    }
  end

  # Handle Selector Update
  def update(
        %{active_label_ids: active_label_ids, selector_id: selector_id},
        %{assigns: %{entity: entity}} = socket
      ) do
    {:ok, socket |> save(entity, %{selector_id => active_label_ids})}
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

  def handle_event("publish", _params, %{assigns: %{entity: entity}} = socket) do
    case validate_for_publish(entity) do
      {:ok, entity} ->
        {
          :noreply,
          socket
          |> save(entity, %{published_at: NaiveDateTime.utc_now()})
          |> update_published_state()
        }

      {:error, changeset} ->
        {
          :noreply,
          socket
          |> assign(changeset: changeset)
          |> flash_error()
        }
    end
  end

  def handle_event("unpublish", _params, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> save(entity, %{published_at: nil})
      |> update_published_state()
    }
  end

  defp update_published_state(%{assigns: %{entity: entity}} = socket) do
    published? = Promotion.published?(entity)
    socket |> assign(published?: published?)
  end

  defp validate_for_publish(entity) do
    changeset = Promotion.changeset(entity, :publish, %{})

    if changeset.valid? do
      {:ok, entity}
    else
      changeset = %{changeset | action: :save}
      {:error, changeset}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
      <ContentArea>
        <Spacing value="XL" />
        <Title1>{{dgettext("eyra-promotion", "form.title")}}</Title1>

        <Bar>
          <BarItem>
            <Case value={{@published? }} >
              <True>
                <Info text={{dgettext("eyra-promotion", "published.true.label")}} />
              </True>
              <False>
                <Warning text={{dgettext("eyra-promotion", "published.false.label")}} />
              </False>
            </Case>
          </BarItem>
          <BarItem>
            <SubHead>{{ @byline }}</SubHead>
          </BarItem>
        </Bar>
        <Spacing value="L" />

        <Form id={{@id}} changeset={{@changeset}} change_event="save" focus={{@focus}} target={{@myself}}>
          <TextInput field={{:title}} label_text={{dgettext("eyra-promotion", "title.label")}} target={{@myself}} />
          <TextInput field={{:subtitle}} label_text={{dgettext("eyra-promotion", "subtitle.label")}} target={{@myself}} />

          <Spacing value="XL" />
          <Title3>{{dgettext("eyra-promotion", "themes.title")}}</Title3>
          <BodyMedium>{{dgettext("eyra-promotion", "themes.label")}}</BodyMedium>
          <Spacing value="XS" />
          <LabelSelector id={{:themes}} labels={{ @theme_labels }} parent={{ %{type: __MODULE__, id: @id} }} />
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-promotion", "image.title")}}</Title3>
          <BodyMedium>{{dgettext("eyra-promotion", "image.label")}}</BodyMedium>
          <Spacing value="XS" />
          <div class="flex flex-row">
            <ImagePreview image_url={{ @image_url }} placeholder="" />
            <Spacing value="S" direction="l" />
            <div class="flex-wrap">
              <SecondaryAlpineButton click="$parent.open = true, $parent.$parent.overlay = true" label={{dgettext("eyra-promotion", "search.different.image.button")}} />
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
          <Spacing value="XL" />
        </Form>
        <Case value={{ @published? }} >
        <True> <!-- Published -->
          <SecondaryLiveViewButton label={{ dgettext("eyra-promotion", "unpublish.button") }} event="unpublish" target={{@myself}} />
        </True>
        <False> <!-- Not published -->
          <PrimaryLiveViewButton label={{ dgettext("eyra-promotion", "publish.button") }} event="publish" target={{@myself}} />
        </False>
      </Case>

      </ContentArea>
    """
  end
end
