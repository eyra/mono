defmodule Systems.Student.Overview do
  use CoreWeb, :live_component

  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Text
  alias Frameworks.Pixel.Selector
  import CoreWeb.UI.Content
  import CoreWeb.UI.Empty

  alias Systems.{
    Student,
    Pool
  }

  # Handle Selector Update
  @impl true
  def update(%{active_item_ids: active_filters, selector_id: :student_filters}, socket) do
    {
      :ok,
      socket
      |> assign(active_filters: active_filters)
      |> prepare_students()
    }
  end

  # Handle Search Bar Update
  @impl true
  def update(%{search_bar: :student_search_bar, query_string: query_string, query: query}, socket) do
    {
      :ok,
      socket
      |> assign(
        query: query,
        query_string: query_string
      )
      |> prepare_students()
    }
  end

  # View model update
  @impl true
  def update(%{students: students} = _params, %{assigns: %{id: _id}} = socket) do
    {
      :ok,
      socket
      |> assign(students: students)
      |> prepare_students()
    }
  end

  # Initial update
  @impl true
  def update(
        %{id: id, students: students, pool: pool} = _params,
        %{assigns: %{myself: target}} = socket
      ) do
    filter_labels = Student.CriteriaFilters.labels([]) ++ Student.Filters.labels([])

    email_button = %{
      action: %{type: :send, event: "email", target: target},
      face: %{type: :label, label: dgettext("eyra-ui", "notify.all"), icon: :chat}
    }

    {
      :ok,
      socket
      |> assign(
        id: id,
        students: students,
        pool: pool,
        active_filters: [],
        filter_labels: filter_labels,
        email_button: email_button
      )
      |> prepare_students()
    }
  end

  @impl true
  def handle_event("email", _, %{assigns: %{filtered_students: filtered_students}} = socket) do
    send(self(), {:email_dialog, %{recipients: filtered_students}})
    {:noreply, socket}
  end

  defp filter(students, nil, _), do: students
  defp filter(students, [], _), do: students

  defp filter(students, filters, pool) do
    students
    |> Enum.filter(
      &(Student.CriteriaFilters.include?(&1.features.study_program_codes, filters) and
          Student.Filters.include?(&1, filters, pool))
    )
  end

  defp query(students, nil), do: students
  defp query(students, []), do: students

  defp query(students, query) when is_list(query) do
    students
    |> Enum.filter(&include?(&1, query))
  end

  defp include?(_student, []), do: true

  defp include?(student, [word]) do
    include?(student, word)
  end

  defp include?(student, [word | rest]) do
    include?(student, word) and include?(student, rest)
  end

  defp include?(_student, ""), do: true

  defp include?(student, word) when is_binary(word) do
    word = String.downcase(word)

    String.contains?(student.profile.fullname |> String.downcase(), word) or
      String.contains?(student.email |> String.downcase(), word) or
      Student.Codes.contains_study_program?(student.features.study_program_codes, word)
  end

  defp prepare_students(
         %{
           assigns: %{
             students: students,
             pool: pool,
             active_filters: active_filters,
             query: query
           }
         } = socket
       ) do
    filtered_students =
      students
      |> filter(active_filters, pool)
      |> query(query)

    filtered_student_items =
      filtered_students
      |> Enum.map(&Pool.Builders.ParticipantItem.view_model(&1, socket))

    socket
    |> assign(
      filtered_students: filtered_students,
      filtered_student_items: filtered_student_items
    )
  end

  # data(pool, :map)
  # data(students, :map)
  # data(query, :any, default: nil)
  # data(query_string, :string, default: "")
  # data(filtered_students, :list)
  # data(filtered_student_items, :list)
  # data(filter_labels, :list)
  # data(email_button, :map)

  attr(:students, :list, required: true)
  attr(:pool, :map, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <%= if Enum.empty?(@students) do %>
        <.empty
          title={dgettext("link-studentpool", "students.empty.title")}
          body={dgettext("link-studentpool", "students.empty.description")}
          illustration="members"
        />
      <% else %>
        <div class="flex flex-row gap-3 items-center">
          <div class="font-label text-label">Filter:</div>
          <.live_component
          module={Selector} id={:student_filters} type={:label} items={@filter_labels} parent={%{type: __MODULE__, id: @id}} />
          <div class="flex-grow" />
          <div class="flex-shrink-0">
            <.live_component
              module={SearchBar}
              id={:student_search_bar}
              query_string={@query_string}
              placeholder={dgettext("link-studentpool", "search.placeholder")}
              debounce="200"
              parent={%{type: __MODULE__, id: @id}}
            />
          </div>
        </div>
        <.spacing value="L" />
        <div class="flex flex-row">
          <Text.title2><%= dgettext("link-studentpool", "tabbar.item.students") %> <span class="text-primary"><%= Enum.count(@filtered_students) %></span></Text.title2>
          <div class="flex-grow" />
          <Button.dynamic {@email_button} />
        </div>
        <.list items={@filtered_student_items} />
      <% end %>
      </Area.content>
    </div>
    """
  end
end
