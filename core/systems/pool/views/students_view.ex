defmodule Systems.Pool.StudentsView do
  use CoreWeb.UI.LiveComponent
  alias CoreWeb.Router.Helpers, as: Routes

  alias Frameworks.Pixel.SearchBar
  alias Frameworks.Pixel.Text.Title2
  alias Frameworks.Pixel.Selector.Selector
  alias CoreWeb.UI.ContentList

  alias Systems.{
    Pool,
    Scholar
  }

  prop(props, :map, required: true)

  data(pool, :map)
  data(students, :map)
  data(query, :any, default: nil)
  data(query_string, :string, default: "")
  data(filtered_students, :list)
  data(filtered_student_items, :list)
  data(filter_labels, :list)
  data(export_button, :map)
  data(email_button, :map)

  # Handle Selector Update
  def update(%{active_item_ids: active_filters, selector_id: :student_filters}, socket) do
    {
      :ok,
      socket
      |> assign(active_filters: active_filters)
      |> prepare_students()
      |> update_buttons()
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
      |> update_buttons()
    }
  end

  # View model update
  def update(%{props: %{students: students}} = _params, %{assigns: %{id: _id}} = socket) do
    {
      :ok,
      socket
      |> assign(students: students)
      |> prepare_students()
      |> update_buttons()
    }
  end

  # Initial update
  def update(
        %{id: id, props: %{students: students, pool: pool}} = _params,
        socket
      ) do
    filter_labels = Pool.CriteriaFilters.labels([]) ++ Pool.StudentFilters.labels([])

    {
      :ok,
      socket
      |> assign(
        id: id,
        students: students,
        pool: pool,
        active_filters: [],
        filter_labels: filter_labels
      )
      |> prepare_students()
      |> update_buttons()
    }
  end

  defp update_buttons(
         %{assigns: %{myself: target, active_filters: active_filters, query: query, pool: pool}} =
           socket
       ) do
    export_path = Routes.export_path(socket, :credits)
    export_filter = active_filters |> Enum.join(",")

    export_query =
      if query do
        query |> Enum.join(",")
      else
        ""
      end

    export_href = "#{export_path}?pool=#{pool.id}&filters=#{export_filter}&query=#{export_query}"

    export_button = %{
      action: %{type: :href, href: export_href},
      face: %{type: :label, label: dgettext("eyra-pool", "export"), icon: :export}
    }

    email_button = %{
      action: %{type: :send, event: "email", target: target},
      face: %{type: :label, label: dgettext("eyra-pool", "notify"), icon: :chat}
    }

    socket
    |> assign(
      export_button: export_button,
      email_button: email_button
    )
  end

  @impl true
  def handle_event("email", _, %{assigns: %{filtered_students: filtered_students}} = socket) do
    send(self(), {:email_dialog, %{recipients: filtered_students}})
    {:noreply, socket}
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
      |> Scholar.Context.filter(active_filters, pool)
      |> Scholar.Context.query(query)

    filtered_student_items =
      filtered_students
      |> Enum.map(&to_view_model(&1, socket))

    socket
    |> assign(
      filtered_students: filtered_students,
      filtered_student_items: filtered_student_items
    )
  end

  defp to_view_model(
         %{
           id: user_id,
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
    subtitle = email

    tag = get_tag(features)
    photo_url = get_photo_url(photo_url, features)
    image = %{type: :avatar, info: photo_url}

    quick_summery =
      inserted_at
      |> CoreWeb.UI.Timestamp.apply_timezone()
      |> CoreWeb.UI.Timestamp.humanize()

    %{
      path: Routes.live_path(socket, Systems.Pool.StudentPage, user_id),
      title: fullname,
      subtitle: subtitle,
      quick_summary: quick_summery,
      tag: tag,
      image: image
    }
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
          <div class="flex-shrink-0">
            <SearchBar
              id={:student_search_bar}
              query_string={@query_string}
              placeholder={dgettext("link-studentpool", "search.placeholder")}
              debounce="200"
              parent={%{type: __MODULE__, id: @id}}
            />
          </div>
        </div>
        <Spacing value="L" />
        <div class="flex flex-row">
          <Title2>{dgettext("link-studentpool", "tabbar.item.students")}: <span class="text-primary">{Enum.count(@filtered_students)}</span></Title2>
          <div class="flex-grow" />
          <DynamicButton vm={@export_button} />
          <div class="w-10" />
          <DynamicButton vm={@email_button} />
        </div>
        <ContentList items={@filtered_student_items} />
      </div>
    </ContentArea>
    """
  end
end
