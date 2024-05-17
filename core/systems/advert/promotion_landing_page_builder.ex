defmodule Systems.Advert.PromotionLandingPageBuilder do
  import CoreWeb.Gettext

  alias Core.Marks
  alias CoreWeb.Router.Helpers, as: Routes
  alias Phoenix.LiveView

  alias Systems.Advert
  alias Systems.Promotion
  alias Systems.Assignment

  def view_model(
        %Advert.Model{
          id: id,
          submission: submission,
          promotion: promotion,
          assignment:
            %{
              info: info
            } = assignment
        },
        %{current_user: user}
      ) do
    extra = Map.take(promotion, [:image_id | Promotion.Model.plain_fields()])

    %{
      id: id,
      byline: byline(),
      themes: themes(promotion),
      organisation: organisation(promotion),
      highlights: highlights(assignment, submission),
      call_to_action: apply_call_to_action(assignment, user),
      languages: Assignment.InfoModel.languages(info),
      devices: Assignment.InfoModel.devices(info)
    }
    |> Map.merge(extra)
  end

  defp byline(), do: "#{dgettext("eyra-alliance", "by.author.label")}: <author?>"

  defp themes(%{themes: themes}, themes_module \\ Advert.Themes) do
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
      Advert.Builders.Highlight.view_model(submission, :reward),
      Advert.Builders.Highlight.view_model(assignment, :duration),
      Advert.Builders.Highlight.view_model(assignment, :status)
    ]
  end

  # FIXME: apply should regsiter as member on the crew and redirected to the workflow
  defp apply_call_to_action(assignment, _user) do
    task_identifier = [""]

    %{
      label: "<some_label?>",
      target: %{type: :event, value: "apply"},
      assignment: assignment,
      task_identifier: task_identifier,
      handle: &handle_apply/1
    }
  end

  def handle_apply(
        %{
          assigns: %{
            current_user: user,
            vm: %{
              call_to_action: %{
                assignment: %{id: id} = assignment,
                task_identifier: task_identifier
              }
            }
          }
        } = socket
      ) do
    case Advert.Public.validate_open(assignment, user) do
      {:error, error} ->
        inform(error, socket)

      :ok ->
        reward_amount = Advert.Public.reward_amount(assignment)

        case Assignment.Public.apply_member(assignment, user, task_identifier, reward_amount) do
          {:ok, _} ->
            LiveView.push_redirect(socket,
              to: Routes.live_path(socket, Systems.Assignment.LandingPage, id)
            )

          {:error, error} ->
            inform(error, socket)
        end
    end
  end

  defp inform(:not_released, socket), do: inform(:closed, socket)
  defp inform(:not_funded, socket), do: inform(:closed, socket)
  defp inform(:no_open_spots, socket), do: inform(:closed, socket)

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

    Phoenix.Component.assign(socket, dialog: dialog)
  end
end
