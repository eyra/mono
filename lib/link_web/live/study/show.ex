defmodule LinkWeb.Study.Show do
  @moduledoc """
  The home screen.
  """
  use LinkWeb, :live_view
  use LinkWeb.LiveViewPowHelper
  use EyraUI.AutoSave, :study
  alias Surface.Components.Form
  alias EyraUI.Form.{TextInput, TextArea, Checkbox}
  alias EyraUI.Hero.HeroSmall
  alias EyraUI.Container.ContentArea
  alias EyraUI.Text.{Title1, Title3}

  alias Link.Studies

  def load(%{"id" => id}, _session, _socket) do
    Studies.get_study!(id)
  end

  defdelegate get_changeset(study, attrs \\ %{}), to: Studies, as: :change_study
  defdelegate save(changeset), to: Studies, as: :update_study

  def render(assigns) do
    ~H"""
      <HeroSmall title={{ dgettext("eyra-study", "study.show.title") }} />
      <ContentArea>
        <Title1>{{ @study.title }}</Title1>
        <Form for={{ @changeset }} change="save">
          <TextInput field={{:title}} label_text={{dgettext("eyra-study", "title.label")}} />
          <TextInput field={{:description}} label_text={{dgettext("eyra-study", "description.label")}} />
          <Title3>{{dgettext("eyra-survey", "config.title")}}</Title3>
          <TextInput field={{:url}} label_text={{dgettext("eyra-survey", "config.url.label")}} />
          <TextInput field={{:nrofsubjects}} label_text={{dgettext("eyra-survey", "config.nrofsubjects.label")}} />
          <Title3>{{dgettext("eyra-survey", "config.devices.title")}}</Title3>
          <Checkbox field={{:mobile_enabled}} label_text={{dgettext("eyra-survey", "mobile.enabled.label")}}/>
          <Checkbox field={{:tablet_enabled}} label_text={{dgettext("eyra-survey", "tablet.enabled.label")}}/>
          <Checkbox field={{:desktop_enabled}} label_text={{dgettext("eyra-survey", "desktop.enabled.label")}}/>
          <Title3>{{dgettext("eyra-survey", "info.title")}}</Title3>
          <TextArea field={{:info}} label_text={{dgettext("eyra-survey", "info.label")}}/>
        </Form>
      </ContentArea>
    """
  end
end
