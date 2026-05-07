defmodule Systems.Zircon.Screening.CriteriaView do
  use CoreWeb, :embedded_live_view

  import Frameworks.Pixel.SidePanel, only: [side_panel: 1]
  import Frameworks.Builder.HTML, only: [library: 1]

  alias Frameworks.Pixel.Text
  alias CoreWeb.UI.Area
  alias CoreWeb.UI.Margin

  alias Systems.Zircon

  def get_model(:not_mounted_at_router, %{"tool" => tool}, _socket) do
    tool
  end

  @impl true
  def mount(
        :not_mounted_at_router,
        %{"title" => title},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(title: title)
      |> assign_criteria_elements()
    }
  end

  defp assign_criteria_elements(
         %{assigns: %{vm: %{criteria_list: criteria_list}, current_user: current_user}} = socket
       ) do
    criteria_elements =
      criteria_list
      |> Enum.with_index()
      |> Enum.map(fn {criterion, index} ->
        dimension_label = extract_dimension_label(criterion)

        LiveNest.Element.prepare_live_component(
          "criterion_form_#{index}",
          Systems.Annotation.Form,
          annotation: criterion,
          label_text: dimension_label,
          user: current_user
        )
      end)

    assign(socket, :criteria_elements, criteria_elements)
  end

  defp extract_dimension_label(criterion) do
    Enum.reduce(criterion.references, "Unknown Dimension", fn reference, acc ->
      case reference do
        %{ontology_ref: %{concept: %{phrase: phrase}}} -> phrase
        _ -> acc
      end
    end)
  end

  @impl true
  def handle_event(
        "add",
        %{"item" => dimension_phrase},
        %{assigns: %{vm: %{dimension_list: dimension_list}}} = socket
      ) do
    if dimension =
         dimension_list |> Enum.find(fn dimension -> dimension.phrase == dimension_phrase end) do
      insert_criterion(dimension, socket)
    else
      Logger.error("Dimension '#{dimension_phrase}' not found in local dimension list")
    end

    {:noreply, socket}
  end

  def handle_event(
        "delete",
        %{"item" => element_id},
        %{assigns: %{model: model, criteria_elements: criteria_elements}} = socket
      ) do
    %{options: options} = Enum.find(criteria_elements, &(&1.id == element_id))
    annotation = Keyword.get(options, :annotation)

    Zircon.Public.delete_screening_tool_criterion(model, annotation)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:signal_test, _}, socket) do
    {:noreply, socket}
  end

  def handle_info({:handle_auto_save_done, _}, socket) do
    {:noreply, socket |> assign_criteria_elements()}
  end

  @impl true
  def handle_view_model_updated(socket) do
    socket |> assign_criteria_elements()
  end

  defp insert_criterion(
         dimension,
         %{assigns: %{model: model, current_user: current_user}} = socket
       ) do
    result = Zircon.Public.insert_screening_tool_criterion(model, dimension, current_user)
    handle_insert_criterion(socket, dimension, result)
  end

  defp handle_insert_criterion(%{parent_pid: nil} = socket, _dimension, _error) do
    # No parent pid means we are running in isolation, no need to show flash message
    socket
  end

  defp handle_insert_criterion(socket, _dimension, {:ok, _}) do
    socket
  end

  defp handle_insert_criterion(
         socket,
         dimension,
         {:error, :validate_criterion_does_not_exist, false, %{}}
       ) do
    Frameworks.Pixel.Flash.push_error(
      socket,
      dgettext("eyra-zircon", "criterion.already_exists", dimension: dimension.phrase)
    )
  end

  defp handle_insert_criterion(socket, dimension, {:error, _, _, _}) do
    Frameworks.Pixel.Flash.push_error(
      socket,
      dgettext("eyra-zircon", "criterion.insert.error", dimension: dimension.phrase)
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div id={:screening_criteria_builder} class="flex flex-row">
        <div class="flex-grow">
          <Area.content>
            <Margin.y id={:page_top} />
            <Text.title2><%= @title %></Text.title2>
            <div class="bg-grey5 rounded-2xl p-6 flex flex-col gap-4">
              <%= for element <- @criteria_elements do %>
                <Zircon.Screening.HTML.criterion_cell id={element.id} title={element.options[:label_text]} live_nest_element={Map.from_struct(element)} socket={@socket} />
              <% end %>
            </div>
          </Area.content>
        </div>
        <div class="flex-shrink-0 w-side-panel">
          <.side_panel id={:screening_criteria_library} parent={:screening_criteria_builder}>
            <Margin.y id={:page_top} />
            <.library
              title={dgettext("eyra-zircon", "screening.criteria.library.title")}
              description={dgettext("eyra-zircon", "screening.criteria.library.description")}
              items={Enum.map(@vm.library_items, &Map.from_struct/1)}
            />
          </.side_panel>
        </div>
      </div>
    """
  end
end
