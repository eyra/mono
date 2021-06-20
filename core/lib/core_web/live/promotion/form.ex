defmodule CoreWeb.Promotion.Form do
  use CoreWeb.LiveForm
  use CoreWeb.FileUploader
  use EyraUI.Selectors.LabelSelector

  import CoreWeb.Gettext

  alias Core.Content.Nodes
  alias Core.Promotions
  alias Core.Promotions.{Promotion, FormData}

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
  prop(owner, :any, required: true)

  data(entity, :any)
  data(form_data, :any)
  data(changeset, :any)
  data(focus, :any, default: "")
  data(myself, :any)

  @impl true
  def save_file(%{assigns: %{entity: entity}} = socket, uploaded_file) do
    socket
    |> schedule_save(entity, %{banner_photo_url: uploaded_file})
    |> update_ui()
  end

  def update(%{id: id, entity_id: entity_id, owner: owner}, socket) do
    entity = Promotions.get!(entity_id)

    {
      :ok,
      socket
      |> init_file_uploader(:photo)
      |> assign(id: id)
      |> assign(entity_id: entity_id)
      |> assign(owner: owner)
      |> update_ui(entity, owner)
    }
  end

  def update(%{image_id: image_id}, %{assigns: %{entity: entity}} = socket) do
    attrs = %{image_id: image_id}

    {
      :ok,
      socket
      |> schedule_save(entity, attrs)
      |> update_ui()
    }
  end

  def handle_event("save", %{"form_data" => attrs}, %{assigns: %{entity: entity}} = socket) do
    {
      :noreply,
      socket
      |> schedule_save(entity, attrs)
      |> update_ui()
    }
  end

  def handle_event(
        "publish",
        _params,
        %{assigns: %{entity: entity, form_data: form_data}} = socket
      ) do
    case validate_for_publish(form_data) do
      {:ok, _form_data} ->
        {:noreply,
         socket
         |> schedule_save(entity, %{published_at: NaiveDateTime.utc_now()})
         |> update_ui()}

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
      |> schedule_save(entity, %{published_at: nil})
      |> update_ui()
    }
  end

  def render(assigns) do
    ~H"""
      <ContentArea>
        <Title1>{{dgettext("eyra-promotion", "form.title")}}</Title1>

        <Bar>
          <BarItem>
            <Case value={{@form_data.is_published }} >
              <True>
                <Info text={{dgettext("eyra-promotion", "published.true.label")}} />
              </True>
              <False>
                <Warning text={{dgettext("eyra-promotion", "published.false.label")}} />
              </False>
            </Case>
          </BarItem>
          <BarItem>
            <SubHead>{{ @form_data.byline }}</SubHead>
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
          <LabelSelector labels={{ @form_data.theme_labels }} target={{@myself}}/>
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-promotion", "image.title")}}</Title3>
          <BodyMedium>{{dgettext("eyra-promotion", "image.label")}}</BodyMedium>
          <Spacing value="XS" />
          <div class="flex flex-row">
            <ImagePreview image_url={{ @form_data.image_url }} placeholder="" />
            <Spacing value="S" direction="l" />
            <div class="flex-wrap">
              <SecondaryAlpineButton click="$parent.open = true, $parent.$parent.overlay = true" label={{dgettext("eyra-survey", "search.different.image.button")}} />
            </div>
          </div>
          <Spacing value="L" />

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
            photo_url={{@form_data.banner_photo_url}}
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
        <Case value={{ @form_data.is_published }} >
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

  defp validate_for_publish(form_data) do
    changeset = FormData.changeset(form_data, :publish, %{})

    if changeset.valid? do
      {:ok, changeset}
    else
      changeset = %{changeset | action: :save}
      {:error, changeset}
    end
  end

  defp update_ui(%{assigns: %{entity: entity, owner: owner}} = socket) do
    update_ui(socket, entity, owner)
  end

  defp update_ui(socket, entity, owner) do
    form_data = FormData.create(entity, owner, owner.profile)
    changeset = FormData.changeset(form_data, :update_ui, %{})

    socket
    |> assign(entity: entity)
    |> assign(form_data: form_data)
    |> assign(changeset: changeset)
  end

  # Label Selector (Themes)

  def all_labels(socket) do
    socket.assigns.form_data.theme_labels
  end

  def update_selected_labels(%{assigns: %{entity: entity}} = socket, labels) do
    socket
    |> schedule_save(entity, %{themes: labels})
  end

  # Save

  def schedule_save(socket, %Promotion{} = entity, attrs) do
    node = Nodes.get!(entity.content_node_id)
    changeset = Promotion.changeset(entity, attrs)
    node_changeset = Promotion.node_changeset(node, entity, attrs)

    socket
    |> schedule_save(changeset, node_changeset)
  end
end
