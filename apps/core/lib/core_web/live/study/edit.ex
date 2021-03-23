defmodule CoreWeb.Study.Edit do
  @moduledoc """
  The study page for owners.
  """
  use CoreWeb, :live_view
  use EyraUI.AutoSave, :study_edit
  alias Surface.Components.Form
  alias EyraUI.Form.{TextInput, UrlInput, NumberInput, TextArea, Checkbox, RadioButtonGroup}
  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Container.{ContentArea, Bar, BarItem}
  alias EyraUI.Text.{Title1, Title3, Title6, SubHead, BodyMedium, Bullet}
  alias EyraUI.Button.{PrimaryLiveViewButton, SecondaryLiveViewButton}
  alias EyraUI.Status.{Info, Warning}
  alias EyraUI.{Spacing, Line}
  alias EyraUI.Case.{Case, True, False}
  alias EyraUI.Card.Card
  alias EyraUI.Selectors.{LabelSelector, ImageSelector}

  alias Core.Studies
  alias Core.Studies.{Study, StudyEdit}
  alias Core.SurveyTools
  alias Core.Marks

  data(uri_origin, :string)
  data(path_provider, :any)

  @impl true
  def load(%{"id" => id}, _session, _socket) do
    study = Studies.get_study!(id)
    study_survey = study |> load_survey_tool()
    StudyEdit.create(study, study_survey)
  end

  def load_survey_tool(%Study{} = study) do
    case study |> Studies.list_survey_tools() do
      [survey_tool] -> survey_tool
      [survey_tool | _] -> survey_tool
      _ -> raise "Expected at least one survey tool for study #{study.title}"
    end
  end

  @impl true
  def get_changeset(study_edit, attrs \\ %{}) do
    study_edit |> StudyEdit.changeset(attrs)
  end

  @impl true
  def save(changeset) do
    if changeset.valid? do
      save_valid(changeset)
    else
      changeset = %{changeset | action: :save}
      {:error, changeset}
    end
  end

  @impl true
  def get_authorization_context(%{"id" => id}, _session, _socket) do
    Studies.get_study!(id)
  end

  @impl true
  def handle_params(_unsigned_params, uri, socket) do
    parsed_uri = URI.parse(uri)
    uri_origin = "#{parsed_uri.scheme}://#{parsed_uri.authority}"
    {:noreply, assign(socket, uri_origin: uri_origin)}
  end

  def save_valid(changeset) do
    study_edit = Ecto.Changeset.apply_changes(changeset)
    study_attrs = StudyEdit.to_study(study_edit)
    survey_tool_attrs = StudyEdit.to_survey_tool(study_edit)

    study = Studies.get_study!(study_edit.study_id)

    {:ok, survey_tool} =
      study
      |> load_survey_tool()
      |> SurveyTools.update_survey_tool(survey_tool_attrs)

    study
    |> Studies.update_study(study_attrs)

    study_edit = StudyEdit.create(study, survey_tool)

    {:ok, study_edit}
  end

  def handle_event("delete", _params, socket) do
    study_edit = socket.assigns[:study_edit]

    Studies.get_study!(study_edit.study_id)
    |> Studies.delete_study()

    {:noreply, push_redirect(socket, to: Routes.live_path(socket, CoreWeb.Dashboard))}
  end

  def handle_event("publish", _params, socket) do
    params = %{published_at: NaiveDateTime.utc_now()}
    study_edit = socket.assigns[:study_edit]

    changeset = StudyEdit.validate_for_publish(study_edit, params)

    if changeset.valid? do
      save(params, socket)
    else
      {:noreply,
       socket
       |> put_flash(:error, "Please correct the indicated errors. #{changeset.errors}")}
    end
  end

  def handle_event("unpublish", _params, socket) do
    params = %{published_at: nil}
    save(params, socket)
  end

  def handle_info({:theme_selector, themes}, socket) do
    params = %{themes: themes}
    study_edit = socket.assigns[:study_edit]

    changeset = StudyEdit.validate_for_publish(study_edit, params)

    if changeset.valid? do
      save(params, socket)
    else
      {:noreply,
       socket
       |> put_flash(:error, "Please correct the indicated errors. #{changeset.errors}")}
    end
  end

  def save(params, socket) do
    study_edit = socket.assigns[:study_edit]
    changeset = get_changeset(study_edit, params)
    {:ok, updated_study_edit} = save(changeset)

    socket =
      socket
      |> assign(
        study_edit: updated_study_edit,
        changeset: changeset,
        save_changeset: changeset
      )

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("eyra-study", "study.edit.title") }} />
      <ContentArea>
        <Bar>
          <BarItem>
            <Info :if={{ @study_edit.is_published }} text={{dgettext("eyra-survey", "published.true.label")}} />
            <Warning :if={{ !@study_edit.is_published }} text={{dgettext("eyra-survey", "published.false.label")}} />
          </BarItem>
          <BarItem>
            <SubHead>{{ @study_edit.byline }}</SubHead>
          </BarItem>
        </Bar>
        <Title1>{{ @study_edit.title }}</Title1>
        <Form for={{ @changeset }} change="save">
          <Spacing value="XL" />
          <Card bg_color="bg-grey1">
            <template slot="title">
              <Title3 color="text-white" >{{dgettext("eyra-survey", "config.title")}}</Title3>
            </template>
            <UrlInput field={{:survey_url}} label_color="text-white" label_text={{dgettext("eyra-survey", "config.url.label")}} read_only={{@study_edit.is_published}}/>
            <Spacing value="S" />
            <Title6 color="text-white">Redirect url</Title6>
            <BodyMedium color="text-grey3">{{ @uri_origin <> @path_provider.live_path(@socket, CoreWeb.Study.Complete, @study_edit.study_id)}}</BodyMedium>
          </Card>
          <Spacing value="XL" />
          <Line />
          <Spacing value="XL" />

          <Case value={{ @study_edit.is_published }} >
            <True> <!-- Published -->
              <Title3>{{dgettext("eyra-survey", "status.title")}}</Title3>
              <Title6>{{dgettext("eyra-survey", "completed.label")}}: <span class="text-success"> {{@study_edit.subject_completed_count}}</span></Title6>
              <Title6>{{dgettext("eyra-survey", "pending.label")}}: <span class="text-warning"> {{@study_edit.subject_pending_count}}</span></Title6>
              <Title6>{{dgettext("eyra-survey", "vacant.label")}}: <span class="text-delete"> {{@study_edit.subject_vacant_count}}</span></Title6>
            </True>
            <False> <!-- Not published -->
              <Title3>{{dgettext("eyra-survey", "Titel")}}</Title3>
              <TextInput field={{:title}} label_text={{dgettext("eyra-study", "title.label")}} />
            </False>
          </Case>

          <Spacing value="XL" />
          <Title3>{{dgettext("eyra-survey", "Thema's")}}</Title3>
          <BodyMedium>{{dgettext("eyra-survey", "Selecteer een of meer themas.")}}</BodyMedium>
          <Spacing value="XS" />
          <LabelSelector id={{:theme_selector}} labels={{ @study_edit.theme_labels }}/>
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-survey", "Afbeelding")}}</Title3>
          <BodyMedium>{{dgettext("eyra-survey", "De gekozen afbeelding wordt zichtbaar op je survey in het overzicht en op de detailpagina van je survey.")}}</BodyMedium>
          <Spacing value="XS" />
          <ImageSelector image_url={{ @study_edit.image_url }} />
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-survey", "Instantie")}}</Title3>
          <RadioButtonGroup field={{:organization}} items={{ Marks.instances() }} checked={{ @study_edit.organization }}/>
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-survey", "Over het onderzoek")}}</Title3>
          <TextArea field={{:description}} label_text={{dgettext("eyra-survey", "info.label")}} read_only={{@study_edit.is_published}}/>
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-survey", "Duur")}}</Title3>
          <TextInput field={{:duration}} label_text={{dgettext("eyra-survey", "duration.label")}} read_only={{@study_edit.is_published}}/>
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-survey", "Beloning")}}</Title3>
          <NumberInput field={{:reward_value}} label_text={{dgettext("eyra-survey", "Bedrag in euro")}} read_only={{@study_edit.is_published}}/>
          <Spacing value="XL" />

          <Title3>{{dgettext("eyra-survey", "Aantal subjects")}}</Title3>
          <NumberInput field={{:subject_count}} label_text={{dgettext("eyra-survey", "config.nrofsubjects.label")}} read_only={{@study_edit.is_published}}/>
          <Spacing value="XL" />


          <Spacing value="L" />
          <Title3>{{dgettext("eyra-survey", "config.devices.title")}}</Title3>
          <Case value={{ @study_edit.is_published }} >
            <True> <!-- Published -->
              <Bullet :if={{@study_edit.phone_enabled}} image={{@path_provider.static_path(@socket, "/images/bullit.svg")}}>
                <BodyMedium>{{dgettext("eyra-survey", "phone.enabled.label")}}</BodyMedium>
              </Bullet>
              <Bullet :if={{@study_edit.tablet_enabled}} image={{@path_provider.static_path(@socket, "/images/bullit.svg")}}>
                <BodyMedium>{{dgettext("eyra-survey", "tablet.enabled.label")}}</BodyMedium>
              </Bullet>
              <Bullet :if={{@study_edit.desktop_enabled}} image={{@path_provider.static_path(@socket, "/images/bullit.svg")}}>
                <BodyMedium>{{dgettext("eyra-survey", "desktop.enabled.label")}}</BodyMedium>
              </Bullet>
            </True>
            <False> <!-- Not published -->
              <Checkbox field={{:phone_enabled}} label_text={{dgettext("eyra-survey", "phone.enabled.label")}}/>
              <Checkbox field={{:tablet_enabled}} label_text={{dgettext("eyra-survey", "tablet.enabled.label")}}/>
              <Checkbox field={{:desktop_enabled}} label_text={{dgettext("eyra-survey", "desktop.enabled.label")}}/>
            </False>
          </Case>
          <Spacing value="XL" />
        </Form>

        <Case value={{ @study_edit.is_published }} >
          <True> <!-- Published -->
            <SecondaryLiveViewButton label={{ dgettext("eyra-survey", "unpublish.button") }} event="unpublish" />
          </True>
          <False> <!-- Not published -->
            <PrimaryLiveViewButton label={{ dgettext("eyra-survey", "publish.button") }} event="publish" />
            <SecondaryLiveViewButton label={{ dgettext("eyra-survey", "delete.button") }} event="delete" />
          </False>
        </Case>
      </ContentArea>
    """
  end
end
