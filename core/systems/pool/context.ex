defmodule Systems.Pool.Context do
  import CoreWeb.Gettext
  alias Core.Pools.Submission

  def get_tag(%Submission{status: status, submitted_at: submitted_at} = submission) do
    case {status, submitted_at} do
      {:idle, nil} ->
        %{text: dgettext("eyra-submission", "status.idle.label"), type: :tertiary}

      {:idle, _} ->
        %{text: dgettext("eyra-submission", "status.retracted.label"), type: :tertiary}

      {:submitted, _} ->
        %{text: dgettext("eyra-submission", "status.submitted.label"), type: :tertiary}

      {:accepted, _} ->
        case published_status(submission) do
          :scheduled ->
            %{
              text: dgettext("eyra-submission", "status.accepted.scheduled.label"),
              type: :tertiary
            }

          :released ->
            %{text: dgettext("eyra-submission", "status.accepted.online.label"), type: :success}

          :closed ->
            %{text: dgettext("eyra-submission", "status.accepted.closed.label"), type: :disabled}
        end

      {:completed, _} ->
        %{text: dgettext("eyra-submission", "status.completed.label"), type: :disabled}
    end
  end

  def published_status(submission) do
    if Submission.schedule_ended?(submission) do
      :closed
    else
      if Systems.Director.context(submission).open?(submission) do
        if Submission.scheduled?(submission) do
          :scheduled
        else
          :released
        end
      else
        :closed
      end
    end
  end
end
