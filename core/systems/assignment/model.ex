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

  def assignable(%{assignable: assignable}) when not is_nil(assignable), do: assignable
  def assignable(%{assignable_survey_tool: assignable}) when not is_nil(assignable), do: assignable
  def assignable(%{assignable_lab_tool: assignable}) when not is_nil(assignable), do: assignable
  def assignable(%{assignable_data_donation_tool: assignable}) when not is_nil(assignable), do: assignable
  def assignable(%{id: id}) do
    raise "no assignable object available for assignment #{id}"
  end

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

  defp vm(%{crew: crew, assignable: assignable} = assignment, Assignment.LandingPage, user) do
    if Crew.Context.member?(crew, user) do
      member = Crew.Context.get_member!(crew, user)
      task = Crew.Context.get_task(crew, member)

      %{
        hero_title: dgettext("link-survey", "task.hero.title"),
        highlights: highlights(assignment, assignable),
        subtitle: assignment_subtitle(task),
        text: assignment_text(task),
        call_to_action: assignment_call_to_action(assignment, user),
      }
    else # expired member
      %{
        hero_title: dgettext("link-survey", "task.hero.title"),
        highlights: highlights(assignment, assignable),
        subtitle: dgettext("eyra-crew", "task.expired.subtitle"),
        text: dgettext("eyra-crew", "task.expired.text"),
        call_to_action: forward_call_to_action(user),
      }
    end
  end

  defp vm(_, Assignment.CallbackPage, user) do
    %{
      hero_title: dgettext("link-survey", "task.hero.title"),
      call_to_action: forward_call_to_action(user)
    }
  end

  defp vm(%{assignable: assignable} = assignment, Promotion.LandingPage, _user) do
    %{
      highlights: highlights(assignment, assignable),
      call_to_action: apply_call_to_action(assignment),
      languages: Assignment.Assignable.languages(assignable),
      devices: Assignment.Assignable.devices(assignable)
    }
  end

  defp assignment_call_to_action(%{crew: crew, assignable: assignable} = assignment, user) do
    if Crew.Context.member?(crew, user) do
      member = Crew.Context.get_member!(crew, user)
      case Crew.Context.get_task(crew, member) do
        nil -> forward_call_to_action(user)
        task ->
          case task.status do
            :pending -> open_call_to_action(assignable, member.public_id)
            :completed -> forward_call_to_action(user)
          end
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

  def handle_apply(%{assigns: %{current_user: user}} = socket, %{assignment: %{id: id, crew: crew} = assignment}, _) do
    if Assignment.Context.open?(assignment) do
      member =
        case Crew.Context.member?(crew, user) do
          true -> Crew.Context.get_member!(crew, user)
          false -> Crew.Context.apply_member!(crew, user)
        end

      _task = Crew.Context.get_or_create_task!(crew, member)

      LiveView.push_redirect(socket, to: Routes.live_path(socket, Systems.Assignment.LandingPage, id))
    else
      inform_closed(socket)
    end
  end

  defp inform_closed(socket) do
    title = dgettext("link-assignment", "closed.dialog.title")
    text = dgettext("link-assignment", "closed.dialog.text")
    inform(socket, title, text)
  end

  defp inform(socket, title, text) do
    buttons = [
      %{
        action: %{type: :send, event: "inform_ok"},
        face: %{type: :primary, label: dgettext("eyra-ui", "ok.button")}
      }
    ]

    dialog = %{
      title: title,
      text: text,
      buttons: buttons
    }

    LiveView.assign(socket, dialog: dialog)
  end

  def handle_forward(%{assigns: %{current_user: user}} = socket, _call_to_action, _model) do
    LiveView.push_redirect(socket, to: Routes.live_path(socket, Accounts.start_page_target(user)))
  end

  defp assignment_subtitle(%{status: :pending}), do: dgettext("link-survey", "task.pending.subtitle")
  defp assignment_subtitle(%{status: :completed}), do: dgettext("link-survey", "task.completed.subtitle")
  defp assignment_subtitle(_), do: nil

  defp assignment_text(%{status: :completed}), do: dgettext("link-survey", "task.completed.text")
  defp assignment_text(_), do: nil

  def highlights(assignment, assignable) do
    duration = Assignment.Assignable.duration(assignable)
    open? = Assignment.Context.open?(assignment)

    status_title = dgettext("link-survey", "status.highlight.title")

    status_text =
      if open? do
        dgettext("link-survey", "status.open.highlight.text")
      else
        dgettext("link-survey", "status.closed.highlight.text")
      end

    duration_title = dgettext("link-survey", "duration.highlight.title")
    duration_text = dgettext("link-survey", "duration.highlight.text", duration: duration)

    [
      %{title: duration_title, text: duration_text},
      %{title: status_title, text: status_text}
    ]
  end
end
