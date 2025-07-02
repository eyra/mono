defmodule Systems.Onyx.LandingPage do
  use Systems.Content.Composer, :live_workspace

  import LiveNest.HTML
  require Logger

  alias Core.Repo
  alias Systems.Observatory
  alias Systems.Onyx

  @impl true
  def get_authorization_context(params, session, socket) do
    get_model(params, session, socket)
  end

  @impl true
  def get_model(_params, _session, _socket) do
    Observatory.SingletonModel.instance()
  end

  @impl true
  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(
        query_string: "",
        model: %{id: :root},
        history: []
      )
      |> update_browser_view()
    }
  end

  @impl true
  def consume_event(
        %{name: "show_model", payload: %{module: module, id: id}},
        %{assigns: %{history: history}} = socket
      ) do
    model =
      module
      |> Repo.get!(id)
      |> Repo.preload(module.preload_graph(:down))

    history = history ++ [model]

    {
      :stop,
      socket
      |> assign(model: model, history: history)
      |> update_browser_view()
    }
  end

  def consume_event(
        %{name: "back_to_model", payload: %{module: module, id: id}},
        %{assigns: %{history: history}} = socket
      ) do
    model = get_model(module, id)
    history = pop_history(history, id) ++ [model]

    {
      :stop,
      socket
      |> assign(model: model, history: history)
      |> update_browser_view()
    }
  end

  def consume_event(x, socket) do
    Logger.warning("unsupported event #{inspect(x)}")
    {:stop, socket}
  end

  defp pop_history(history, id) do
    model_index = Enum.find_index(history, fn model -> model.id == id end)

    if model_index do
      Enum.slice(history, 0, model_index)
    else
      []
    end
  end

  defp get_model(module, id) do
    module
    |> Repo.get!(id)
    |> Repo.preload(module.preload_graph(:down))
  end

  def update_browser_view(
        %{assigns: %{vm: %{entities: entities}, model: model, history: history}} = socket
      ) do
    browser_view =
      LiveNest.Element.prepare_live_view(
        get_browser_view_id(model),
        Onyx.BrowserView,
        history: history,
        model: model,
        entities: entities
      )

    assign(socket, :browser_view, browser_view)
  end

  def notify_modal_controller(socket, modal_id) do
    Logger.warning("notify_modal_controller #{modal_id}")
    socket
  end

  defp get_browser_view_id(%module{id: id}) do
    "browser_view_#{module}_#{id}"
  end

  defp get_browser_view_id(_) do
    "browser_view"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.live_workspace title={dgettext("eyra-onyx", "landing.title")} menus={@menus} modal={@modal} socket={@socket}>
        <.element {Map.from_struct(@browser_view)} socket={@socket} />
      </.live_workspace>
    </div>
    """
  end
end
