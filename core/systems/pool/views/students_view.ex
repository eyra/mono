defmodule Systems.Pool.StudentsView do
  use CoreWeb.UI.LiveComponent

  alias Core.Enums.StudyProgramCodes
  alias Core.Pools.CriteriaFilters

  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Text.Title2
  alias Frameworks.Pixel.Selector.Selector
  alias CoreWeb.UI.ContentList

  prop(props, :map, required: true)

  data(students, :map)
  data(query, :any, default: nil)
  data(query_string, :string, default: "")
  data(filtered_students, :map)
  data(filter_labels, :list)

  # Handle Selector Update
  def update(%{active_item_ids: active_filters, selector_id: :student_filters}, socket) do
    {
      :ok,
      socket
      |> assign(active_filters: active_filters)
      |> prepare_students()
    }
  end

  # Handle Search Bar Update
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
  def update(%{props: %{students: students}} = _params, %{assigns: %{id: _id}} = socket) do
    {
      :ok,
      socket
      |> assign(students: students)
      |> prepare_students()
    }
  end

  # Initial update
  def update(%{id: id, props: %{students: students}} = _params, socket) do
    filter_labels = CriteriaFilters.labels([])

    {
      :ok,
      socket
      |> assign(
        id: id,
        students: students,
        active_filters: [],
        filter_labels: filter_labels
      )
      |> prepare_students()
    }
  end

  defp filter(students, nil), do: students
  defp filter(students, []), do: students

  defp filter(students, filters) do
    students
    |> Enum.filter(&CriteriaFilters.include?(&1.features.study_program_codes, filters))
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
      StudyProgramCodes.contains_study_program?(student.features.study_program_codes, word) or
      StudyProgramCodes.contains_year?(student.features.study_program_codes, word)
  end

  defp prepare_students(
         %{assigns: %{students: students, active_filters: active_filters, query: query}} = socket
       ) do
    socket
    |> assign(
      filtered_students:
        students
        |> filter(active_filters)
        |> query(query)
        |> Enum.map(&to_view_model(&1, socket))
    )
  end

  defp to_view_model(
         %{
           email: email,
           inserted_at: inserted_at,
           profile: %{
             fullname: fullname,
             photo_url: photo_url
           },
           features: features
         },
         socket
       ) do
    subtitle =
      [email | get_study_programs(features)]
      |> Enum.join(" ▪︎ ")

    tag = get_tag(features)
    photo_url = get_photo_url(photo_url, features)
    image = %{type: :avatar, info: photo_url}

    quick_summery =
      inserted_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    %{
      path: Routes.live_path(socket, Systems.Pool.OverviewPage),
      title: fullname,
      subtitle: subtitle,
      quick_summary: quick_summery,
      tag: tag,
      image: image
    }
  end

  defp get_study_programs(%{study_program_codes: study_program_codes})
       when is_list(study_program_codes) and study_program_codes != [] do
    study_program_codes
    |> Enum.map(&StudyProgramCodes.translate(&1))
  end

  defp get_study_programs(_) do
    []
  end

  def get_tag(%{study_program_codes: [_ | _]}) do
    %{type: :success, text: dgettext("link-studentpool", "student.tag.complete")}
  end

  def get_tag(_) do
    %{type: :delete, text: dgettext("link-studentpool", "student.tag.incomplete")}
  end

  def get_photo_url(nil, %{gender: :man}), do: "/images/profile_photo_default_male.svg"
  def get_photo_url(nil, %{gender: :woman}), do: "/images/profile_photo_default_female.svg"
  def get_photo_url(nil, _), do: "/images/profile_photo_default.svg"
  def get_photo_url(photo_url, _), do: photo_url

  def render(assigns) do
    ~F"""
    <ContentArea>
      <MarginY id={:page_top} />
      <Empty
        :if={@students == []}
        title={dgettext("link-studentpool", "students.empty.title")}
        body={dgettext("link-studentpool", "students.empty.description")}
        illustration="members"
      />
      <div :if={not Enum.empty?(@students)}>
        <div class="flex flex-row gap-3 items-center">
          <div class="font-label text-label">Filter:</div>
          <Selector id={:student_filters} items={@filter_labels} parent={%{type: __MODULE__, id: @id}} />
          <div class="flex-grow" />
          <SearchBar
            id={:student_search_bar}
            query_string={@query_string}
            placeholder={dgettext("link-studentpool", "search.placeholder")}
            debounce="200"
            parent={%{type: __MODULE__, id: @id}}
          />
        </div>
        <Spacing value="L" />
        <Title2>{dgettext("link-studentpool", "tabbar.item.students")}: <span class="text-primary">{Enum.count(@filtered_students)}</span></Title2>
        <ContentList items={@filtered_students} />
      </div>
    </ContentArea>
    """
  end
end
