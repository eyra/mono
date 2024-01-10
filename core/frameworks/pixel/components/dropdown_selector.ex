defmodule Frameworks.Pixel.DropdownSelector do
  use CoreWeb, :live_component

  import Frameworks.Pixel.FormHelpers, only: [get_border_color: 1]

  alias Frameworks.Pixel.Dropdown
  alias Frameworks.Pixel.Text

  # Warning update
  @impl true
  def update(
        %{model: %{warning: warning}},
        socket
      ) do
    {:ok, socket |> assign(warning: warning)}
  end

  # Realtime update
  @impl true
  def update(
        %{model: %{options: options}},
        socket
      ) do
    {
      :ok,
      socket
      |> assign(options: options)
      |> validate_selection()
      |> update_selector_text()
    }
  end

  # Initial update
  @impl true
  def update(
        %{
          id: id,
          options: options,
          parent: parent,
          selected_option_index: selected_option_index,
          background: background,
          debounce: debounce
        },
        socket
      ) do
    {
      :ok,
      socket
      |> assign(
        id: id,
        options: options,
        parent: parent,
        selected_option_index: selected_option_index,
        selected_option: nil,
        background: background,
        debounce: debounce,
        show_options?: false,
        warning: nil
      )
      |> validate_selection()
      |> update_selector_text()
    }
  end

  defp validate_selection(
         %{assigns: %{selected_option: nil, selected_option_index: nil}} = socket
       ) do
    socket
  end

  defp validate_selection(
         %{
           assigns: %{
             options: options,
             selected_option_index: selected_option_index,
             selected_option: nil
           }
         } = socket
       ) do
    case Enum.at(options, selected_option_index) do
      nil ->
        socket
        |> assign(
          selected_option_index: nil,
          selected_option: nil
        )

      selected_option ->
        socket
        |> assign(selected_option: selected_option)
    end
  end

  defp validate_selection(
         %{
           assigns: %{
             options: options,
             selected_option: %{id: selected_option_id},
             selected_option_index: nil,
             parent: parent
           }
         } = socket
       ) do
    selected_option_index = Enum.find_index(options, &(&1.id == selected_option_id))

    case selected_option_index do
      nil ->
        update_target(parent, %{selector: :reset})
        warning = dgettext("link-lab", "update.warning.time.slot.no.longer.available")
        socket |> assign(selected_option_index: nil, selected_option: nil, warning: warning)

      index ->
        socket |> assign(selected_option_index: index, warning: nil)
    end
  end

  defp update_selector_text(%{assigns: %{selected_option_index: nil}} = socket) do
    socket |> assign(selector_text: "-")
  end

  defp update_selector_text(
         %{assigns: %{options: options, selected_option_index: selected_option_index}} = socket
       ) do
    selector_text =
      options
      |> Enum.at(selected_option_index)
      |> Map.get(:label)

    socket |> assign(selector_text: selector_text)
  end

  @impl true
  def handle_event(
        "toggle_options",
        _,
        %{assigns: %{show_options?: show_options?, parent: parent}} = socket
      ) do
    update_target(parent, %{selector: :toggle, show_options?: !show_options?})

    {
      :noreply,
      socket
      |> assign(
        show_options?: !show_options?,
        warning: nil
      )
    }
  end

  @impl true
  def handle_event(
        "option_click",
        %{"item" => selected_item},
        %{assigns: %{options: options, parent: parent}} = socket
      ) do
    selected_option_index = String.to_integer(selected_item)

    selected_option =
      options
      |> Enum.at(selected_option_index)

    update_target(parent, %{selector: :selected, option: selected_option})

    {
      :noreply,
      socket
      |> assign(
        selected_option: selected_option,
        selected_option_index: selected_option_index,
        show_options?: false
      )
      |> update_selector_text()
    }
  end

  defp icon(%{show_options?: false}), do: :dropdown
  defp icon(_), do: :dropup

  # data(selector_text, :string)
  # data(show_options?, :boolean)
  # data(warning, :string)

  attr(:options, :list, required: true)
  attr(:parent, :any, required: true)
  attr(:selected_option_index, :integer)
  attr(:background, :atom, default: :light)
  attr(:debounce, :string, default: "0")

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-click="toggle_options" phx-target={@myself} class="relative">
      <div class={"text-grey1 text-bodymedium font-body pl-3 w-full border-2 border-solid rounded h-44px #{get_border_color({@show_options?, @warning != nil, @background})}"}>
        <div class="flex flex-row items-center h-full w-full cursor-pointer">
          <Text.body_medium><span class="whitespace-pre-wrap"><%= @selector_text %></span></Text.body_medium>
          <div class="flex-grow" />
          <img class="mr-3" src={~p"/images/icons/#{"#{icon(assigns)}.svg"}"} alt="Dropdown">
        </div>
      </div>
      <%= if @warning do %>
        <div>
          <.spacing value="XXS" />
          <div class="text-warning text-caption font-caption"><%= @warning %></div>
        </div>
      <% end %>
      <%= if @show_options? do %>
        <div class="absolute z-20 left-0 top-48px bg-black bg-opacity-20 w-full">
          <Dropdown.options options={@options} target={@myself} />
        </div>
      <% end %>
    </div>
    """
  end
end
