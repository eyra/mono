defmodule MicaWeb.UI.StepProgress do
  @moduledoc """
    Horizontal progress through a fixed number of steps: one Prism step indicator per
    step on a track that fills up to the current step. The steps are not selectable.
    A finished step shows a check, the current step its number, an upcoming step a
    grey check.

    Each step is `%{number: integer(), label: String.t(), status: :complete | :current |
    :incomplete}`; the label is for screen readers.
  """
  use MicaWeb, :ui

  alias Frameworks.Pixel

  attr(:steps, :list, required: true)
  attr(:testid, :string, default: "step-progress")

  def step_progress(assigns) do
    assigns = assign(assigns, fill: fill(assigns.steps))

    ~H"""
    <div data-testid={@testid} class="relative h-7">
      <div class="absolute inset-x-[14px] top-[13px] h-[2px] rounded-full bg-grey4">
        <div class="h-[2px] rounded-full bg-primary" style={"width: #{@fill}%"} />
      </div>
      <ol class="absolute inset-0 flex flex-row items-center justify-between">
        <li
          :for={step <- @steps}
          data-testid="step-progress-step"
          data-status={step.status}
          aria-label={step.label}
          aria-current={if step.status == :current, do: "step"}
        >
          <Pixel.step_indicator status={step.status} class="w-7 h-7 text-[13px] leading-[13px]">
            <%= if step.status == :current do %>
              <%= step.number %>
            <% else %>
              <.check />
            <% end %>
          </Pixel.step_indicator>
        </li>
      </ol>
    </div>
    """
  end

  @doc "The current step's number, larger, e.g. before the step's title."
  attr(:number, :integer, required: true)

  # Prism's step_indicator doesn't re-render its inner block when only that block
  # changes; inside a comprehension it renders afresh for each new number.
  def step_number(assigns) do
    ~H"""
    <Pixel.step_indicator
      :for={number <- [@number]}
      status={:current}
      class="w-9 h-9 text-[16px] leading-4"
      data-testid="step-number"
    >
      <%= number %>
    </Pixel.step_indicator>
    """
  end

  # Drawn in the step indicator's foreground colour
  defp check(assigns) do
    ~H"""
    <svg width="13" height="13" viewBox="0 0 13 13" fill="none" aria-hidden="true">
      <path d="M10.8333 3.25L4.875 9.20833L2.16667 6.5" stroke="currentColor" stroke-width="1.73333" stroke-linecap="round" stroke-linejoin="round" />
    </svg>
    """
  end

  # The track fills from the first step to the current one
  defp fill(steps) when length(steps) < 2, do: 0

  defp fill(steps) do
    reached = Enum.count(steps, &(&1.status != :incomplete))
    (max(reached, 1) - 1) / (length(steps) - 1) * 100
  end
end
