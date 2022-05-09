defmodule Systems.DataDonation.UploadPage do
  defmodule StoreResultsError do
    @moduledoc false
    defexception [:message]
  end

  import Phoenix.LiveView

  use Surface.LiveView, layout: {CoreWeb.LayoutView, "live.html"}
  use CoreWeb.LiveLocale
  use CoreWeb.LiveAssignHelper
  use CoreWeb.Layouts.Stripped.Component, :data_donation

  import CoreWeb.Gettext
  alias CoreWeb.Router.Helpers, as: Routes
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

  @impl true
  def mount(_params, %{"flow" => flow, "storage_info" => storage_info} = _session, socket) do
    vm = DataDonation.Context.get(flow)
    tabs = create_tabs(vm)

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
     assign(socket, vm: vm, storage_info: storage_info, tabs: tabs, finish_button: finish_button)
     |> update_menus()}
  end

  defp create_tabs(%{file_type: file_type} = vm) do
    script_content = read_script(vm)

    [
      %{
        id: :welcome,
        action: nil,
        title: dgettext("eyra-data-donation", "tabbar.item.welcome"),
        forward_title: dgettext("eyra-data-donation", "tabbar.item.welcome.forward"),
        component: WelcomeSheet,
        props: vm,
        type: :sheet,
        align: :left
      },
      %{
        id: :file_selection,
        action: nil,
        title: dgettext("eyra-data-donation", "tabbar.item.file_selection"),
        forward_title: dgettext("eyra-data-donation", "tabbar.item.file_selection.forward"),
        component: FileSelectionSheet,
        props: %{script: script_content, file_type: file_type},
        type: :sheet
      },
      %{
        id: :submit_data,
        action: nil,
        title: dgettext("eyra-data-donation", "tabbar.item.submit_data"),
        forward_title: dgettext("eyra-data-donation", "tabbar.item.submit_data.forward"),
        component: SubmitDataSheet,
        props: vm,
        type: :sheet
      }
    ]
  end

  @impl true
  def handle_event(
        "donate",
        %{"data" => data},
        %{assigns: %{vm: %{redirect_to: redirect_to}}} = socket
      ) do
    store_results(socket, data)

    socket =
      case redirect_to do
        :thanks -> push_redirect(socket, to: Routes.live_path(socket, DataDonation.ThanksPage))
        _ -> socket
      end

    {:noreply, socket}
  end

  @impl true
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

  def store_results(
        %{assigns: %{vm: %{storage: storage_key} = vm, storage_info: storage_info}} = _socket,
        data
      )
      when is_binary(data) do
    storage = storage(storage_key)
    storage.store(storage_info, vm, data)
  end

  defp storage(storage_key) do
    config = config()

    case Keyword.get(config, storage_key) do
      nil ->
        raise StoreResultsError, "Could not store the results, invalid config for #{storage_key}"

      value ->
        value
    end
  end

  defp config() do
    Application.fetch_env!(:core, :data_donation_storage_backend)
  end

  defp read_script(%{script: script}) do
    Application.app_dir(:core, "priv/repo")
    |> Path.join(script)
    |> File.read!()
  end
end

defimpl Plug.Exception, for: Systems.DataDonation.UploadPage.StoreResultsError do
  def status(_exception), do: 500
  def actions(_), do: []
end
