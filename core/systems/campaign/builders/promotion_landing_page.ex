defmodule Systems.Campaign.Builders.PromotionLandingPage do
  import CoreWeb.Gettext
  import Frameworks.Utility.ViewModel

  alias Core.Marks
  alias CoreWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView

  alias Systems.{
    Campaign,
    Promotion,
    Assignment
  }

  def view_model(
        %Campaign.Model{} = campaign,
        assigns,
        url_resolver
      ) do
    campaign
    |> Campaign.Model.flatten()
    |> view_model(assigns, url_resolver)
  end

  def view_model(
        %{
          id: id,
          authors: authors,
          submission: submission,
          promotion: promotion,
          promotable:
            %{
              assignable_experiment: experiment
            } = assignment
        },
        _assigns,
        _url_resolver
      ) do
    %{
      id: id,
      byline: byline(authors),
      themes: themes(promotion),
      organisation: organisation(promotion),
      highlights: highlights(assignment, submission),
      call_to_action: apply_call_to_action(assignment),
      languages: Assignment.ExperimentModel.languages(experiment),
      devices: Assignment.ExperimentModel.devices(experiment)
    }
    |> merge(promotion |> Map.take([:image_id | Promotion.Model.plain_fields()]))
  end

  defp byline(authors) when is_list(authors) do
    "#{dgettext("link-survey", "by.author.label")}: " <>
      Enum.map_join(authors, ", ", & &1.fullname)
  end

  defp themes(%{themes: themes}, themes_module \\ Link.Enums.Themes) do
    themes
    |> themes_module.labels()
    |> Enum.filter(& &1.active)
    |> Enum.map_join(", ", & &1.value)
  end

  defp organisation(%{marks: marks}) do
    if id = organisation_id(marks) do
      Enum.find(
        Marks.instances(),
        &(&1.id == id)
      )
    end
  end

  defp organisation_id([first_mark | _]), do: first_mark
  defp organisation_id(_), do: nil

  defp highlights(assignment, submission) do
    [
      Campaign.Builders.Highlight.view_model(submission, :reward),
      Campaign.Builders.Highlight.view_model(assignment, :duration),
      Campaign.Builders.Highlight.view_model(assignment, :status)
    ]
  end

  defp apply_call_to_action(%{assignable_experiment: experiment} = assignment) do
    %{
      label: Assignment.ExperimentModel.apply_label(experiment),
      target: %{type: :event, value: "apply"},
      assignment: assignment,
      handle: &handle_apply/1
    }
  end

  def handle_apply(
        %{
          assigns: %{
            current_user: user,
            vm: %{call_to_action: %{assignment: %{id: id} = assignment}}
          }
        } = socket
      ) do
    case Assignment.Context.can_apply_as_member?(assignment, user) do
      {:error, error} ->
        inform(error, socket)

      {:ok} ->
        reward_amount = Campaign.Context.reward_amount(assignment)
        Assignment.Context.apply_member(assignment, user, reward_amount)

        LiveView.push_redirect(socket,
          to: Routes.live_path(socket, Systems.Assignment.LandingPage, id)
        )
    end
  end

  defp inform(:closed, socket) do
    title = dgettext("link-assignment", "closed.dialog.title")
    text = dgettext("link-assignment", "closed.dialog.text")
    inform(socket, title, text)
  end

  defp inform(:excluded, socket) do
    title = dgettext("link-assignment", "excluded.dialog.title")
    text = dgettext("link-assignment", "excluded.dialog.text")
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
end
