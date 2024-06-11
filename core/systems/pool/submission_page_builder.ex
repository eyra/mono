defmodule Systems.Pool.SubmissionPageBuilder do
  use CoreWeb, :verified_routes

  import CoreWeb.Gettext

  # FIXME: Pool should not have relation with Advert
  alias Systems.Advert

  def view_model(submission, assigns) do
    %{
      actions: create_actions(submission, assigns),
      submission: submission,
      active_menu_item: :home,
      form:
        %{
          # FIXME
        }
    }
  end

  defp create_actions(%{status: status} = submission, %{uri_path: uri_path}) do
    submission
    |> create_preview_path(uri_path)
    |> action_map()
    |> create_actions(status)
  end

  defp create_actions(map, :idle), do: [map[:preview], map[:accept], map[:complete]]
  defp create_actions(map, :submitted), do: [map[:preview], map[:accept], map[:complete]]
  defp create_actions(map, :accepted), do: [map[:preview], map[:complete], map[:retract]]
  defp create_actions(map, :completed), do: [map[:preview], map[:accept]]

  defp action_map(preview_path) do
    preview_action = %{type: :redirect, to: preview_path}
    publish_action = %{type: :send, event: "publish"}
    retract_action = %{type: :send, event: "retract"}
    complete_action = %{type: :send, event: "complete"}

    %{
      accept: %{
        action: publish_action,
        face: %{
          type: :primary,
          label: dgettext("link-ui", "publish.button"),
          bg_color: "bg-success"
        }
      },
      preview: %{
        action: preview_action,
        face: %{
          type: :primary,
          label: dgettext("link-ui", "preview.button"),
          bg_color: "bg-primary"
        }
      },
      retract: %{
        action: retract_action,
        face: %{type: :icon, icon: :retract, alt: dgettext("link-ui", "retract.button")}
      },
      complete: %{
        action: complete_action,
        face: %{
          type: :primary,
          label: dgettext("link-ui", "complete.button"),
          text_color: "text-grey1",
          bg_color: "bg-tertiary"
        }
      }
    }
  end

  defp create_preview_path(submission, uri_path) do
    %{promotion: %{id: promotion_id}} = Advert.Public.get_by_submission(submission, [:promotion])
    ~p"/promotion/#{promotion_id}?preview=true&back=#{uri_path}"
  end
end
