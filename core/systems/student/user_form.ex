defmodule Systems.Student.UserForm do
  use CoreWeb.LiveForm

  alias Frameworks.Pixel.Selector
  alias Frameworks.Pixel.Text

  alias Systems.Account
  alias Systems.Account.FeaturesModel
  alias Systems.Student
  alias Systems.Budget
  alias Systems.Content

  @impl true
  def update(%{id: id, user: user}, socket) do
    entity = Account.Public.get_features(user)

    current_year = Student.Public.academic_year()
    last_year = current_year - 1

    courses_finised = courses_finised(user, last_year)

    classes =
      current_year
      |> classes()
      |> remove_finished(current_year, courses_finised)

    title = "VU SBE #{Student.Public.academic_year()}"

    {
      :ok,
      socket
      |> assign(id: id)
      |> assign(user: user)
      |> assign(entity: entity)
      |> assign(student_classes: classes)
      |> assign(title: title)
      |> update_ui()
    }
  end

  defp courses_finised(user, year) do
    user
    |> Budget.Public.list_wallets()
    |> Enum.filter(
      &(year?(&1, year) and
          finished?(&1))
    )
    |> Enum.map(&Student.Course.get_by_wallet(&1))
  end

  defp remove_finished(classes, current_year, courses_finised) do
    classes
    |> Enum.filter(&(not finished_last_year?(&1, current_year, courses_finised)))
  end

  defp finished_last_year?(class, current_year, [_ | _] = finished_courses) do
    course = Student.Class.get_course(class)

    finished_courses
    |> Enum.find(&successor?(&1, course, current_year)) != nil
  end

  defp finished_last_year?(_, _, _), do: false

  defp successor?(
         %{identifier: finished_currency} = _finished_course,
         %{identifier: currency} = _course,
         current_year
       ) do
    Student.Public.successor?(finished_currency, currency, current_year)
  end

  defp finished?(%{balance_credit: balance_credit} = wallet) do
    balance_credit >= Student.Public.get_target(wallet)
  end

  defp year?(%{identifier: identifier}, year), do: year?(identifier, year)

  defp year?(["wallet", currency_name, _], year),
    do: String.ends_with?(currency_name, "_#{year}")

  defp classes(academic_year) do
    Student.Public.list_classes([":#{academic_year}"], [
      :links,
      short_name_bundle: Content.TextBundleModel.preload_graph(:full)
    ])
  end

  defp update_ui(socket) do
    socket
    |> update_student_classes()
    |> compose_child(:study_program_codes)
  end

  @impl true
  def compose(:study_program_codes, %{student_class_labels: items}) do
    %{
      module: Selector,
      params: %{
        items: items,
        type: :checkbox
      }
    }
  end

  defp update_student_classes(
         %{
           assigns: %{
             student_classes: student_classes,
             user: user
           }
         } = socket
       ) do
    active_classes = Student.Public.list_classes(user)

    active_codes =
      student_classes
      |> Enum.filter(&active?(&1, active_classes))
      |> Enum.map(&Student.Class.code(&1.identifier))

    locale = Gettext.get_locale(CoreWeb.Gettext)
    student_class_labels = Student.Class.selector_labels(student_classes, locale, active_codes)

    socket
    |> assign(student_class_labels: student_class_labels)
  end

  defp active?(%{id: class_id}, [_ | _] = active_classes) do
    Enum.find(active_classes, &(&1.id == class_id)) != nil
  end

  defp active?(_, _), do: false

  def save(socket, %Account.FeaturesModel{} = entity, type, attrs) do
    changeset = FeaturesModel.changeset(entity, type, attrs)

    socket
    |> save(changeset)
    |> update_ui()
  end

  @impl true
  def handle_event(
        "active_item_ids",
        %{active_item_ids: active_item_ids, source: %{name: field}},
        %{assigns: %{entity: entity}} = socket
      ) do
    active_item_ids =
      active_item_ids
      |> Enum.map(&String.to_atom(&1))

    {:noreply, socket |> save(entity, :auto_save, %{field => active_item_ids})}
  end

  attr(:user, :map, required: true)
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <Area.content>
      <Margin.y id={:page_top} />
      <Area.form>
        <Text.title2><%= dgettext("eyra-ui", "tabbar.item.student") %></Text.title2>
        <Text.body_medium><%= dgettext("eyra-account", "feature.study.description") %></Text.body_medium>
        <.spacing value="M" />
        <Text.title4><%= @title %></Text.title4>
        <.spacing value="S" />
        <.child name={:study_program_codes} fabric={@fabric} />
      </Area.form>
      </Area.content>
    </div>
    """
  end
end
