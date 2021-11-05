defmodule Systems.Assignment.Model do
  @moduledoc """
  The assignment type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.{
    Assignment,
    Promotion
  }

  schema "assignments" do
    belongs_to(:assignable_survey_tool, Core.Survey.Tool)
    belongs_to(:assignable_lab_tool, Core.Lab.Tool)
    belongs_to(:assignable_data_donation_tool, Core.DataDonation.Tool)
    belongs_to(:crew, Systems.Crew.Model)
    belongs_to(:auth_node, Core.Authorization.Node)

    field(:director, Ecto.Enum, values: [:campaign])

    timestamps()
  end

  @fields ~w()a

  defimpl GreenLight.AuthorizationNode do
    def id(assignment), do: assignment.auth_node_id
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:director])
    |> cast(attrs, @fields)
  end

  def flatten(assignment) do
    assignment
    |> Map.take([:id, :crew, :director])
    |> Map.put(:assignable, assignable(assignment))
  end

  def assignable(%{assignable_survey_tool: assignable}) when not is_nil(assignable), do: assignable
  def assignable(%{assignable_lab_tool: assignable}) when not is_nil(assignable), do: assignable
  def assignable(%{assignable_data_donation_tool: assignable}) when not is_nil(assignable), do: assignable
  def assignable(%{id: id}), do: raise "no assignable object available for assignment #{id}"

  def preload_graph(:full) do
    [:crew, :assignable_survey_tool, :assignable_data_donation_tool, assignable_lab_tool: [:time_slots]]
  end

  def preload_graph(_), do: []

end

defimpl Frameworks.Utility.ViewModelBuilder, for: Systems.Assignment.Model do

  import CoreWeb.Gettext

  alias Phoenix.LiveView
  alias CoreWeb.Router.Helpers, as: Routes
  alias Core.Accounts

  alias Systems.{
    Assignment,
    Promotion,
    Crew
  }

  def view_model(%Assignment.Model{} = assignment, page, user, _url_resolver) do
    assignment
    |> Assignment.Model.flatten()
    |> vm(page, user)
  end

  defp vm(%{crew: crew} = assignment, Assignment.LandingPage, user) do
    member = Crew.Context.get_member!(crew, user)
    %{status: status} = task = Crew.Context.get_task(crew, member)

    %{
      hero_title: dgettext("link-survey", "task.hero.title"),
      subtitle: assignment_subtitle(task),
      text: assignment_text(task),
      highlights: assignment_highlights(task),
      call_to_action: assignment_call_to_action(assignment, user),
      withdraw_redirect: withdraw_call_to_action(),
      completed?: status == :completed
    }
  end

  defp vm(_, Assignment.CallbackPage, user) do
    %{
      hero_title: dgettext("link-survey", "task.hero.title"),
      call_to_action: forward_call_to_action(user)
    }
  end

  defp vm(%{crew: crew, assignable: assignable} = assignment, Promotion.LandingPage, _user) do
    %{
      highlights: promotion_highlights(crew, assignable),
      call_to_action: apply_call_to_action(assignment),
      languages: Assignment.Assignable.languages(assignable),
      devices: Assignment.Assignable.devices(assignable)
    }
  end

  defp withdraw_call_to_action() do
    %{
      label: dgettext("eyra-link", "marketplace.button"),
      target: %{type: :event, value: "marketplace"},
      handle: &handle_withdraw/3
    }
  end

  defp assignment_call_to_action(%{crew: crew, assignable: assignable} = assignment, user) do
    if Crew.Context.member?(crew, user) do
      member = Crew.Context.get_member!(crew, user)
      %{status: status} = Crew.Context.get_task(crew, member)
      case status do
        :completed -> forward_call_to_action(user)
        _ -> open_call_to_action(assignable, member.public_id)
      end
    else
      apply_call_to_action(assignment)
    end
  end

  defp apply_call_to_action(%{assignable: assignable} = assignment) do
    %{
      label: Assignment.Assignable.apply_label(assignable),
      target: %{type: :event, value: "apply"},
      assignment: assignment,
      handle: &handle_apply/3
    }
  end

  defp open_call_to_action(assignable, panl_id) do
    %{
      label: Assignment.Assignable.open_label(assignable),
      target: %{type: :event, value: "open"},
      path: Assignment.Assignable.path(assignable, panl_id),
      handle: &handle_open/3
    }
  end

  defp forward_call_to_action(user) do
    %{
      label: Accounts.start_page_title(user),
      target: %{type: :event, value: "forward"},
      handle: &handle_forward/3
    }
  end

  def handle_open(%{assigns: %{current_user: user}} = socket, %{path: path}, %{crew: crew}) do
    member = Crew.Context.get_member!(crew, user)
    task = Crew.Context.get_or_create_task!(crew, member)
    Crew.Context.start_task!(task)
    LiveView.redirect(socket, external: path)
  end

  def handle_apply(%{assigns: %{current_user: user}} = socket, %{assignment: %{id: id, crew: crew}}, _) do
    member =
      case Crew.Context.member?(crew, user) do
        true -> Crew.Context.get_member!(crew, user)
        false -> Crew.Context.apply_member!(crew, user)
      end

    _task = Crew.Context.get_or_create_task!(crew, member)

    LiveView.push_redirect(socket, to: Routes.live_path(socket, Systems.Assignment.LandingPage, id))
  end

  def handle_forward(%{assigns: %{current_user: user}} = socket, _call_to_action, _model) do
    LiveView.push_redirect(socket, to: Routes.live_path(socket, Accounts.start_page_target(user)))
  end

  def handle_withdraw(%{assigns: %{current_user: user}} = socket, _, %{crew: crew} ) do
    Crew.Context.withdraw_member(crew, user)
    LiveView.push_redirect(socket, to: Routes.live_path(socket, Link.Marketplace)) #FIXME: Fallback page should be configurable per bundle
  end

  defp assignment_subtitle(%{status: :pending}), do: dgettext("link-survey", "task.pending.subtitle")
  defp assignment_subtitle(%{status: :completed}), do: dgettext("link-survey", "task.completed.subtitle")
  defp assignment_subtitle(_), do: nil

  defp assignment_text(%{status: :completed}), do: dgettext("link-survey", "task.completed.text")
  defp assignment_text(_), do: nil

  defp assignment_highlights(nil), do: nil
  defp assignment_highlights(%{started_at: started_at, completed_at: completed_at} = _task) do
    started_title = dgettext("link-survey", "started.highlight.title")

    started_text =
      case started_at do
        nil ->
          dgettext("link-survey", "started.highlight.default")

        date ->
          date
          |> CoreWeb.UI.Timestamp.apply_timezone()
          |> CoreWeb.UI.Timestamp.humanize()
      end

    completed_title = dgettext("link-survey", "completed.highlight.title")

    completed_text =
      case completed_at do
        nil ->
          dgettext("link-survey", "completed.highlight.default")

        date ->
          date
          |> CoreWeb.UI.Timestamp.apply_timezone()
          |> CoreWeb.UI.Timestamp.humanize()
      end
    [
      %{title: started_title, text: started_text},
      %{title: completed_title, text: completed_text}
    ]
  end

  def promotion_highlights(crew, assignable) do

    spot_count = Assignment.Assignable.spot_count(assignable)
    duration = Assignment.Assignable.duration(assignable)

    occupied_spot_count = Crew.Context.count_tasks(crew, [:pending, :completed])
    open_spot_count = max(0, spot_count - occupied_spot_count)

    spots_title = dgettext("link-survey", "spots.highlight.title")

    spots_text =
      dgettext("link-survey", "spots.highlight.text", open: open_spot_count, total: spot_count)

    duration_title = dgettext("link-survey", "duration.highlight.title")
    duration_text = dgettext("link-survey", "duration.highlight.text", duration: duration)

    [
      %{title: duration_title, text: duration_text},
      %{title: spots_title, text: spots_text}
    ]
  end
end
