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

  def mount(%{"id" => tool_id}, _session, socket) do
    tool = DataDonation.Context.get!(tool_id)
    tabs = create_tabs(tool)

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
     assign(socket, tabs: tabs, finish_button: finish_button, tool: tool)
     |> update_menus()}

    # {:ok,
    #  socket
    #  |> assign(:result, nil)
    #  |> assign(:tool, tool)
    #  |> assign(:changeset, DataDonation.UploadModel.changeset(%{}))}
  end

  defp create_tabs(tool) do
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
        props: %{script: tool.script},
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
        %{assigns: %{tool: tool}} = socket
      ) do
    DataDonation.ToolModel.store_results(tool, data)
    {:noreply, push_redirect(socket, to: Routes.live_path(socket, ThanksPage, tool.id))}
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
end
