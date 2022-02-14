defmodule Systems.DataDonation.UploadPage do
  use CoreWeb, :live_view
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  alias CoreWeb.Layouts.Stripped.Component, as: Stripped
  alias CoreWeb.UI.Navigation.{ActionBar, Tabbar, TabbarContent, TabbarFooter, TabbarArea}

  alias Systems.DataDonation.{FileSelectionForm, DataExtractionForm, SubmitDataForm}

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

  def mount(%{}, _session, socket) do
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
     assign(socket, tabs: tabs, finish_button: finish_button)
     |> update_menus()}
  end

  defp create_tabs() do
    [
      %{
        id: :file_selection,
        action: nil,
        title: dgettext("eyra-data-donation", "tabbar.item.file_selection"),
        forward_title: dgettext("eyra-data-donation", "tabbar.item.file_selection.forward"),
        component: FileSelectionForm,
        props: %{},
        type: :form
      },
      %{
        id: :data_extraction,
        action: nil,
        title: dgettext("eyra-data-donation", "tabbar.item.data_extraction"),
        forward_title: dgettext("eyra-data-donation", "tabbar.item.data_extraction.forward"),
        component: DataExtractionForm,
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
        %{assigns: %{}} = socket
      ) do
    store_results(data)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, ThanksPage))}
  end

  def render(assigns) do
    ~F"""
    <Stripped user={@current_user} menus={@menus}>
      <div id="data-donation" phx-hook="PythonUploader"
           data-after-completion-tab="submit_data">
        <TabbarArea tabs={@tabs}>
          <ActionBar>
            <Tabbar vm={%{initial_tab: :file_selection}}/>
          </ActionBar>
          <TabbarContent />
          <TabbarFooter>
          </TabbarFooter>
        </TabbarArea>
      </div>
    </Stripped>

    """
  end

  def store_results(data) when is_binary(data) do
    storage().store(data)
  end

  defp storage do
    Application.fetch_env!(:core, :data_donation_storage_backend)
  end
end
