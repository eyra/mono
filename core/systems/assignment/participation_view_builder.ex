defmodule Systems.Assignment.ParticipationViewBuilder do
  @moduledoc """
  View model for `Systems.Assignment.ParticipationView` — shown after the owner
  has reviewed a participant's contribution (accepted or rejected). Terminal
  from the participant's perspective; no retry.
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment

  def view_model(%Assignment.Model{} = assignment, %{current_user: user}) do
    participation = Assignment.Public.get_participation(assignment, user)
    outcome = outcome(participation)

    %{
      outcome: outcome,
      title: title(outcome),
      body: body(outcome, participation),
      reason: reason(outcome, participation),
      home_button: home_button()
    }
  end

  defp outcome(%Assignment.ParticipationModel{rejected_at: %NaiveDateTime{}}), do: :rejected
  defp outcome(%Assignment.ParticipationModel{accepted_at: %NaiveDateTime{}}), do: :accepted

  defp title(:accepted), do: dgettext("eyra-assignment", "participation.title.accepted")
  defp title(:rejected), do: dgettext("eyra-assignment", "participation.title.rejected")

  defp body(:accepted, _participation),
    do: dgettext("eyra-assignment", "participation.body.accepted")

  defp body(:rejected, %Assignment.ParticipationModel{rejected_message: reason})
       when is_binary(reason) and reason != "",
       do: dgettext("eyra-assignment", "participation.body.rejected.with_reason")

  defp body(:rejected, _participation),
    do: dgettext("eyra-assignment", "participation.body.rejected")

  defp reason(:rejected, %Assignment.ParticipationModel{rejected_message: reason})
       when is_binary(reason) and reason != "",
       do: reason

  defp reason(_outcome, _participation), do: nil

  defp home_button do
    %{
      action: %{type: :redirect, to: "/"},
      face: %{
        type: :plain,
        icon: :back,
        icon_align: :left,
        label: dgettext("eyra-assignment", "participation.back_home.button")
      }
    }
  end
end
