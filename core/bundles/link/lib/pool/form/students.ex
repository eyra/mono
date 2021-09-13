defmodule Link.Pool.Form.Students do
  use CoreWeb.UI.LiveComponent

  alias Core.Accounts
  alias Core.Enums.StudyProgramCodes

  alias EyraUI.Text.Title2
  alias CoreWeb.UI.ContentListItem

  prop(user, :any, required: true)
  data(students, :map)

  def update(_params, socket) do
    students =
      Accounts.list_students([:profile, :features])
      |> Enum.map(&to_view_model(&1, socket))

    {
      :ok,
      socket
      |> assign(students: students)
    }
  end

  defp to_view_model(%{
    email: email,
    inserted_at: inserted_at,
    profile: %{
      fullname: fullname,
      photo_url: photo_url
    },
    features: features
  }, socket) do

    subtitle =
      [email] ++ get_study_programs(features)
      |> Enum.join(" ▪︎ ")

    tag = get_tag(features)
    photo_url = get_photo_url(photo_url, features)
    image = %{type: :avatar, info: photo_url}

    quick_summery =
      inserted_at
      |> Coreweb.UI.Timestamp.apply_timezone()
      |> Coreweb.UI.Timestamp.humanize()

    %{
      path: Routes.live_path(socket, Link.Pool.Overview),
      title: fullname,
      subtitle: subtitle,
      quick_summary: quick_summery,
      tag: tag,
      image: image
    }
  end

  defp get_study_programs(%{study_program_codes: study_program_codes}) when is_list(study_program_codes) and study_program_codes != [] do
    study_program_codes
    |> Enum.map(&StudyProgramCodes.translate(&1))
  end

  defp get_study_programs(_) do
    []
  end

  def get_tag(%{study_program_codes: study_program_codes}) do
    case study_program_codes do
      [_ | _] -> %{type: :success, text: dgettext("link-studentpool", "student.tag.complete")}
      _ -> %{type: :delete, text: dgettext("link-studentpool", "student.tag.incomplete")}
    end
  end

  def get_photo_url(nil, %{gender: :man}), do: "/images/profile_photo_default_male.svg"
  def get_photo_url(nil, %{gender: :woman}), do: "/images/profile_photo_default_female.svg"
  def get_photo_url(nil, _), do: "/images/profile_photo_default.svg"
  def get_photo_url(photo_url, _), do: photo_url

  def render(assigns) do
    ~H"""
      <ContentArea>
        <MarginY id={{:page_top}} />
        <Empty :if={{ @students == [] }}
          title={{ dgettext("link-studentpool", "students.empty.title") }}
          body={{ dgettext("link-studentpool", "students.empty.description") }}
          illustration="members"
        />
        <div :if={{ not Enum.empty?(@students) }}>
          <Title2>{{ dgettext("link-studentpool", "tabbar.item.students") }}: <span class="text-primary">{{ Enum.count(@students) }}</span></Title2>
          <ContentListItem :for={{item <- @students}} vm={{item}} />
        </div>
        <MarginY id={{:page_footer_top}} />
      </ContentArea>
    """
  end
end
