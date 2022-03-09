defmodule Systems.DataDonation.UploadPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  alias CoreWeb.Layouts.Stripped.Component, as: Stripped
  alias CoreWeb.UI.Navigation.{ActionBar, Tabbar, TabbarContent, TabbarFooter, TabbarArea}

  alias Systems.DataDonation.{
    WelcomeSheet,
    FileSelectionSheet,
    SubmitDataSheet
  }

  alias Systems.{
    DataDonation
  }

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
    pilot_model = DataDonation.PilotModel.view_model()

    [
      %{
        id: :welcome,
        action: nil,
        title: dgettext("eyra-data-donation", "tabbar.item.welcome"),
        forward_title: dgettext("eyra-data-donation", "tabbar.item.welcome.forward"),
        component: WelcomeSheet,
        props: pilot_model,
        type: :sheet,
        align: :left
      },
      %{
        id: :file_selection,
        action: nil,
        title: dgettext("eyra-data-donation", "tabbar.item.file_selection"),
        forward_title: dgettext("eyra-data-donation", "tabbar.item.file_selection.forward"),
        component: FileSelectionSheet,
        props: %{script: @script, file_type: pilot_model.file_type},
        type: :sheet
      },
      %{
        id: :submit_data,
        action: nil,
        title: dgettext("eyra-data-donation", "tabbar.item.submit_data"),
        forward_title: dgettext("eyra-data-donation", "tabbar.item.submit_data.forward"),
        component: SubmitDataSheet,
        props: pilot_model,
        type: :sheet
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

    {:noreply,
     push_redirect(socket, to: Routes.live_path(socket, DataDonation.ThanksPage, participant_id))}
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

  def __mix_recompile__?() do
    Application.app_dir(:core, "priv/repo")
    |> Path.join("script.py")
    |> File.read!() != unquote(@script)
  end
end
