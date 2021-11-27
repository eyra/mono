defmodule Systems.Assignment.Model do
  @moduledoc """
  The assignment type.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.{
    Assignment,
    Promotion,
    Survey,
    Lab
  }

  schema "assignments" do
    belongs_to(:assignable_survey_tool, Survey.ToolModel)
    belongs_to(:assignable_lab_tool, Lab.ToolModel)
    belongs_to(:assignable_data_donation_tool, Core.DataDonation.Tool)
    belongs_to(:crew, Systems.Crew.Model)
    belongs_to(:auth_node, Core.Authorization.Node)

    field(:director, Ecto.Enum, values: [:campaign])

    timestamps()
  end

  @fields ~w()a

  defimpl Frameworks.GreenLight.AuthorizationNode do
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

  alias Link.Enums.OnlineStudyLanguages

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

    if Crew.Context.member?(crew, user) do
      member = Crew.Context.get_member!(crew, user)
      task = Crew.Context.get_task(crew, member)
      contact_enabled? = contact_enabled?(task)

      %{
        public_id: member.public_id,
        hero_title: dgettext("link-survey", "task.hero.title"),
        highlights: highlights(assignment, :assignment),
        subtitle: assignment_subtitle(task),
        text: assignment_text(task),
        call_to_action: assignment_call_to_action(assignment, user),
        contact_enabled?: contact_enabled?,
        cancel_enabled?: cancel_enabled?(task)
      }
    else # expired member
      %{
        public_id: nil,
        hero_title: dgettext("link-survey", "task.hero.title"),
        highlights: highlights(assignment, :assignment),
        subtitle: dgettext("eyra-crew", "task.expired.subtitle"),
        text: dgettext("eyra-crew", "task.expired.text"),
        call_to_action: forward_call_to_action(user),
        contact_enabled?: false,
        cancel_enabled?: false
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
      highlights: highlights(assignment, :promotion),
      call_to_action: apply_call_to_action(assignment),
      languages: Assignment.Assignable.languages(assignable),
      devices: Assignment.Assignable.devices(assignable)
    }
  end

  defp cancel_enabled?(%{status: status, started_at: started_at, expired: expired?}) do
    started? = started_at != nil

    case {status, started?, expired?} do
      {:pending, true, false} -> true
      _ -> false
    end
  end

  defp contact_enabled?(%{status: :rejected}), do: true
  defp contact_enabled?(_), do: false

  defp assignment_call_to_action(%{crew: crew, assignable: assignable} = assignment, user) do
    if Crew.Context.member?(crew, user) do
      member = Crew.Context.get_member!(crew, user)
      case Crew.Context.get_task(crew, member) do
        nil -> forward_call_to_action(user)
        task ->
          case task.status do
            :pending -> open_call_to_action(assignable, member.public_id)
            _completed -> forward_call_to_action(user)
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
    task = Crew.Context.get_task(crew, member)
    Crew.Context.start_task(task)
    LiveView.redirect(socket, external: path)
  end

  def handle_apply(%{assigns: %{current_user: user}} = socket, %{assignment: %{id: id} = assignment}, _) do
    if Assignment.Context.open?(assignment) do
      Assignment.Context.apply_member(assignment, user)
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
  defp assignment_subtitle(%{status: :accepted}), do: dgettext("link-survey", "task.accepted.subtitle")
  defp assignment_subtitle(%{status: :rejected}), do: dgettext("link-survey", "task.rejected.subtitle")
  defp assignment_subtitle(_), do: nil

  defp assignment_text(%{status: :completed}), do: dgettext("link-survey", "task.completed.text")
  defp assignment_text(%{status: :accepted}), do: dgettext("link-survey", "task.accepted.text")
  defp assignment_text(%{status: :rejected, rejected_message: rejected_message}) do
    dgettext("link-survey", "task.rejected.text", reason: rejected_message)
  end
  defp assignment_text(_), do: nil

  defp highlights(assignment, :assignment) do
    [
      highlight(assignment, :duration),
      highlight(assignment, :language),
    ]
  end

  defp highlights(assignment, :promotion) do
    [
      highlight(assignment, :duration),
      highlight(assignment, :status),
    ]
  end

  defp highlight(%{assignable: assignable}, :duration) do
    duration = Assignment.Assignable.duration(assignable)

    duration_title = dgettext("link-survey", "duration.highlight.title")
    duration_text = dgettext("link-survey", "duration.highlight.text", duration: duration)

    %{title: duration_title, text: duration_text}
  end

  defp highlight(assignment, :status) do
    open? = Assignment.Context.open?(assignment)
    status_title = dgettext("link-survey", "status.highlight.title")

    status_text =
      if open? do
        dgettext("link-survey", "status.open.highlight.text")
      else
        dgettext("link-survey", "status.closed.highlight.text")
      end

    %{title: status_title, text: status_text}
  end

  defp highlight(%{assignable: assignable}, :language) do
    language_title = dgettext("link-survey", "language.highlight.title")

    language_text =
      Assignment.Assignable.languages(assignable)
      |> language_text()

    %{title: language_title, text: language_text}
  end

  defp language_text([]), do: "?"
  defp language_text(languages) when is_list(languages) do
    languages
    |> Enum.map(&translate(&1))
    |> Enum.join(" | ")
  end

  defp translate(nil), do: "?"
  defp translate(language) do
    OnlineStudyLanguages.translate(language)
  end

end
