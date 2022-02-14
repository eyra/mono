defmodule Systems.DataDonation.UploadPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  alias CoreWeb.Layouts.Stripped.Component, as: Stripped
  alias CoreWeb.UI.Navigation.{ActionBar, Tabbar, TabbarContent, TabbarFooter, TabbarArea}

  alias Systems.DataDonation.{WelcomeForm, FileSelectionForm, SubmitDataForm}

  alias Systems.{
    DataDonation
  }

  alias Systems.DataDonation.ThanksPage

  @script Application.app_dir(:core, "priv/repo")
          |> Path.join("script.py")
          |> File.read!()

  data(result, :any)
  data(tool, :any)
  data(user, :any)
  data(loading, :boolean, default: true)
  data(step2, :css_class, default: "hidden")
  data(step3, :css_class, default: "hidden")
  data(step4, :css_class, default: "hidden")
  data(summary, :any, default: "")
  data(extracted, :any, default: "")
  data(tabs, :any)

  def mount(%{"participant_id" => participant_id}, _session, socket) do
    unless String.match?(participant_id, ~r/[a-zA-Z0-9_\-]+/) do
      throw(:invalid_participant_id)
    end

    tabs = create_tabs()

    finish_button = %{
      action: %{
        type: :send,
        event: "donate"
      },
      face: %{
        type: :primary,
        label: dgettext("eyra-ui", "onboarding.forward")
      }
    }

    {:ok,
     assign(socket, tabs: tabs, finish_button: finish_button, participant_id: participant_id)
     |> update_menus()}
  end

  defp create_tabs() do
    [
      %{
        id: :welcome,
        action: nil,
        title: dgettext("eyra-data-donation", "tabbar.item.welcome"),
        forward_title: dgettext("eyra-data-donation", "tabbar.item.welcome.forward"),
        component: WelcomeForm,
        props: %{},
        type: :form
      },
      %{
        id: :file_selection,
        action: nil,
        title: dgettext("eyra-data-donation", "tabbar.item.file_selection"),
        forward_title: dgettext("eyra-data-donation", "tabbar.item.file_selection.forward"),
        component: FileSelectionForm,
        props: %{script: @script},
        type: :form
      },
      %{
        id: :submit_data,
        action: nil,
        title: dgettext("eyra-data-donation", "tabbar.item.submit_data"),
        forward_title: dgettext("eyra-data-donation", "tabbar.item.submit_data.forward"),
        component: SubmitDataForm,
        props: %{},
        type: :form
      }
    ]
  end

  @impl true
  def handle_event(
        "donate",
        %{"data" => data},
        %{assigns: %{participant_id: participant_id}} = socket
      ) do
    store_results(participant_id, data)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, ThanksPage))}
  end

  def render(assigns) do
    ~F"""
    <Stripped user={@current_user} menus={@menus}>
      <div id="data-donation" phx-hook="PythonUploader"
           data-after-completion-tab="submit_data">
        <TabbarArea tabs={@tabs}>
          <ActionBar>
            <Tabbar vm={%{initial_tab: :welcome}}/>
          </ActionBar>
          <TabbarContent />
          <TabbarFooter>
          </TabbarFooter>
        </TabbarArea>
      </div>
    </Stripped>

    """
  end

  def store_results(participant_id, data) when is_binary(data) do
    storage().store(participant_id, data)
  end

  defp storage do
    Application.fetch_env!(:core, :data_donation_storage_backend)
  end
end
