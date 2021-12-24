defmodule Systems.Lab.DayView do
  use CoreWeb.UI.LiveComponent

  require Logger

  alias CoreWeb.UI.Timestamp

  alias Frameworks.Pixel.Button.DynamicButton
  alias Frameworks.Pixel.Form.{Form, TextInput, NumberInput, DateInput}
  alias Frameworks.Pixel.Spacing
  alias Frameworks.Pixel.Line

  alias Systems.{
    Lab
  }

  import CoreWeb.Gettext

  prop day_model, :map, default: nil
  prop target, :any, required: true

  data date, :date
  data title, :string
  data entity, :map
  data changeset, :map
  data focus, :string, default: ""

  def update(%{id: id, day_model: %{date: date} = day_model, target: target}, socket) do
    changeset =
      day_model
      |> Lab.DayModel.changeset(:init, %{})

    {
      :ok,
      socket |> assign(
        id: id,
        target: target,
        day_model: day_model,
        date: date,
        changeset: changeset
      )
      |> update_title()
    }
  end

  def update(%{active_item_id: active_item_id, selector_id: selector_id}, %{assigns: %{day_model: %{entries: entries} = day_model}} = socket) do
    start_time = selector_id |> Atom.to_string() |> String.to_integer()
    enabled? = active_item_id != nil

    entries =
      entries
      |> update_entries(start_time, enabled?)

    day_model = %{day_model | entries: entries}

    {
      :ok,
      socket |> assign(
        day_model: day_model
      )
    }
  end

  defp update_entries(entries, start_time, enabled?) when is_list(entries) do
    case entries |> Enum.find_index(&has_start_time(&1, start_time)) do
      nil -> entries
      index ->
        %{data: data} = entry = Enum.at(entries, index)

        entries
        |> List.replace_at(index,
          %{entry | data: %{data | enabled: enabled?}}
        )
    end
  end

  defp has_start_time(%{data: %{start_time: og_start_time}}, start_time), do: og_start_time == start_time
  defp has_start_time(_entry, _start_time), do: false

  defp update_title(%{assigns: %{date: date}} = socket) do
    assign(socket, title: Timestamp.humanize_date(date))
  end

  @impl true
  def handle_event("update", %{"day_model" => new_day_model}, %{assigns: %{day_model: day_model}} = socket) do
    changeset = Lab.DayModel.changeset(day_model, :submit, new_day_model)

    date =
      new_day_model["date"]
      |> Timestamp.parse_user_input_date()
      |> Timestamp.to_date()

    {
      :noreply,
      socket
      |> assign(
        changeset: changeset,
        date: date
      )
      |> update_title()
    }
  end

  @impl true
  def handle_event("focus", %{"field" => field}, socket) do
    {:noreply, socket |> assign(focus: field)}
  end

  @impl true
  def handle_event("reset_focus", _, socket) do
    {:noreply, socket |> assign(focus: "")}
  end

  defp buttons(_target) do
    [
      %{
        action: %{type: :submit},
        face: %{type: :primary, label: dgettext("link-lab", "day.schedule.submit.button")}
      }
    ]
  end

  @impl true
  def render(assigns) do
    ~F"""
      <div class="p-8 bg-white shadow-2xl rounded" phx-click="reset_focus" phx-target={@myself}>
        <div>
          <div class="text-title5 font-title5 sm:text-title3 sm:font-title3">
            {@title}
          </div>
          <Spacing value="XS" />

          <Form id="reject_form" changeset={@changeset} change_event="update" submit="reject" target={@myself} focus={@focus} >
            <Wrap>
              <DateInput field={:date} />
            </Wrap>
            <div class="flex flex-row gap-8">
              <div class="flex-grow">
                <TextInput field={:location} label_text={dgettext("link-lab", "day.schedule.location.label")} debounce="0"/>
              </div>
              <div class="w-24">
                <NumberInput field={:number_of_seats} label_text={dgettext("link-lab", "day.schedule.seats.label")} debounce="0"/>
              </div>
            </div>
            <Line />
            <div class="h-image-header overflow-scroll">
              <div class="h-2"></div>
              <div :for={entry <- @day_model.entries} >
                <Lab.DayEntryListItem :props={entry} target={%{type: __MODULE__, id: @id}}/>
              </div>
            </div>
            <Line />
            <Spacing value="M" />
            <div class="flex flex-row gap-4">
              <DynamicButton :for={button <- buttons(@myself)} vm={button} />
            </div>
          </Form>
        </div>
      </div>
    """
  end
end

defmodule Systems.Lab.DayView.Example do
  use Surface.Catalogue.Example,
    subject: Systems.Lab.DayView,
    catalogue: Frameworks.Pixel.Catalogue,
    title: "Lab day view",
    height: "1680px",
    direction: "vertical",
    container: {:div, class: ""}

  data new_day_model, :map, default: %Systems.Lab.DayModel{
    state: :new,
    date: ~D[2022-12-13],
    location: "Lab 007, Unit 4.02",
    number_of_seats: 10,
    entries: [
      %{type: :time_slot, data: %{enabled: true, start_time: 900}},
      %{type: :time_slot, data: %{enabled: true, start_time: 930}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1000}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1030}},
      %{type: :break},
      %{type: :time_slot, data: %{enabled: true, start_time: 1100}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1130}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1200}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1230}},
      %{type: :break},
      %{type: :time_slot, data: %{enabled: true, start_time: 1300}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1330}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1400}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1430}},
      %{type: :break},
      %{type: :time_slot, data: %{enabled: true, start_time: 1500}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1530}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1600}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1630}},
      %{type: :time_slot, data: %{enabled: true, start_time: 1700}},
      %{type: :break},
      %{type: :time_slot, data: %{enabled: false, start_time: 1730}},
      %{type: :time_slot, data: %{enabled: false, start_time: 1800}},
      %{type: :time_slot, data: %{enabled: false, start_time: 1830}},
      %{type: :time_slot, data: %{enabled: false, start_time: 1900}},
      %{type: :time_slot, data: %{enabled: false, start_time: 1930}}
    ]
  }

  def render(assigns) do
    ~F"""
    <DayView id={:day_view_example} day_model={@new_day_model} target={self()}/>
    """
  end

  # def update(%{reject: :submit, rejection: rejection}, socket) do
  #   IO.puts("submit: rejection=#{rejection}")
  #   {:ok, socket}
  # end

  # def update(%{reject: :cancel}, socket) do
  #   IO.puts("cancel")
  #   {:ok, socket}
  # end

end
