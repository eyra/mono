defmodule Frameworks.Pixel.Dropdown.Selector do
  use CoreWeb.UI.LiveComponent

  import Frameworks.Pixel.FormHelpers, only: [focus_border_color: 1]

  alias Frameworks.Pixel.Dropdown
  alias Frameworks.Pixel.Text.BodyMedium

  prop(field, :atom, required: true)
  prop(options, :list, required: true)
  prop(parent, :any, required: true)
  prop(selected_option_index, :integer)
  prop(background, :atom, default: :light)
  prop(debounce, :string, default: "0")

  data(selector_text, :string)
  data(show_options?, :boolean)
  data(warning, :string)

  # Warning update
  def update(
        %{model: %{warning: warning}},
        socket
      ) do
    {:ok, socket |> assign(warning: warning)}
  end

  # Realtime update
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
        background: background,
        debounce: debounce,
        show_options?: false,
        warning: nil
      )
      |> validate_selection()
      |> update_selector_text()
    }
  end

  defp validate_selection(%{assigns: %{selected_option_index: nil}} = socket) do
    socket |> assign(selected_option: nil)
  end

  defp validate_selection(
         %{
           assigns: %{
             options: options,
             selected_option: %{id: selected_option_id},
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

  defp border_color(%{warning: warning}) when not is_nil(warning), do: "border-warning"
  defp border_color(%{show_options?: false}), do: "border-grey3"
  defp border_color(%{background: background}), do: focus_border_color(background)

  defp icon(%{show_options?: false}), do: :dropdown
  defp icon(_), do: :dropup

  def render(assigns) do
    ~F"""
    <div phx-click="toggle_options" phx-target={@myself} class="relative">
      <div class={"text-grey1 text-bodymedium font-body pl-3 w-full border-2 border-solid rounded h-44px #{border_color(assigns)}"}>
        <div class="flex flex-row items-center h-full w-full cursor-pointer">
          <BodyMedium><span class="whitespace-pre-wrap">{@selector_text}</span></BodyMedium>
          <div class="flex-grow" />
          <img class="mr-3" src={"/images/icons/#{icon(assigns)}.svg"} alt="Dropdown">
        </div>
      </div>
      <div :if={@warning != nil}>
        <Spacing value="XXS" />
        <div class="text-warning text-caption font-caption">{@warning}</div>
      </div>
      <div :if={@show_options?} class="absolute z-20 left-0 top-48px bg-black bg-opacity-20 w-full">
        <Dropdown.OptionsView options={@options} target={@myself} />
      </div>
    </div>
    """
  end
end

defmodule Frameworks.Pixel.Dropdown.Selector.Example do
  use Surface.Catalogue.Example,
    subject: Frameworks.Pixel.Dropdown.Selector,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Dropdown selector",
    height: "1280px",
    direction: "vertical",
    container: {:div, class: ""}

  def handle_info(%{selector: :selected, option: %{label: label}}, socket) do
    IO.puts("selected -> #{label}")
    {:noreply, socket}
  end

  def handle_info(%{selector: :toggle, show_options?: show_options?}, socket) do
    IO.puts("toggle -> #{show_options?}")
    {:noreply, socket}
  end

  def handle_info(%{selector: :reset}, socket) do
    IO.puts("reset")
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <Selector
      id={:dropdown_selector}
      field={:dropdown_selector}
      selected_option_index={nil}
      parent={self()}
      options={[
        %{id: 1, label: "Dropdown item 1"},
        %{id: 2, label: "Dropdown item 2"},
        %{id: 3, label: "Dropdown item 3"},
        %{id: 4, label: "Dropdown item 4"},
        %{id: 5, label: "Dropdown item 5"},
        %{id: 6, label: "Dropdown item 6"},
        %{id: 7, label: "Dropdown item 7"},
        %{id: 8, label: "Dropdown item 8"},
        %{id: 9, label: "Dropdown item 9"},
        %{id: 10, label: "Dropdown item 10"},
        %{id: 11, label: "Dropdown item 11"},
        %{id: 12, label: "Dropdown item 12"},
        %{id: 13, label: "Dropdown item 13"}
      ]}
    />
    """
  end
end
