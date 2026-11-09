defmodule MicaWeb.UI.StepProgress do
  @moduledoc """
    Horizontal progress through a fixed number of steps: one dot per step on a
    track that fills up to the current step. The steps are not selectable.

    Each step is `%{label: String.t(), status: :complete | :current | :incomplete}`;
    the label is for screen readers.
  """
  use MicaWeb, :ui

  attr(:steps, :list, required: true)
  attr(:testid, :string, default: "step-progress")

  def step_progress(assigns) do
    assigns = assign(assigns, fill: fill(assigns.steps))

    ~H"""
    <div data-testid={@testid} class="relative h-[10px] rounded-full bg-grey4">
      <div class="absolute left-0 top-0 h-[10px] rounded-full bg-primary" style={"width: #{@fill}%"} />
      <ol class="absolute inset-0 flex flex-row items-center justify-between">
        <li
          :for={step <- @steps}
          data-testid="step-progress-step"
          data-status={step.status}
          aria-label={step.label}
          aria-current={if step.status == :current, do: "step"}
          class={"shrink-0 rounded-full #{dot_class(step.status)}"}
        />
      </ol>
    </div>
    """
  end

  defp dot_class(:current), do: "w-4 h-4 bg-primary"
  defp dot_class(:complete), do: "w-3 h-3 bg-primary"
  defp dot_class(_), do: "w-3 h-3 bg-grey3"

  # The track fills from the first dot to the current one
  defp fill(steps) when length(steps) < 2, do: 0

  defp fill(steps) do
    reached = Enum.count(steps, &(&1.status != :incomplete))
    (max(reached, 1) - 1) / (length(steps) - 1) * 100
  end
end
