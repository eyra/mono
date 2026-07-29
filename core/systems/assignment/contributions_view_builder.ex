defmodule Systems.Assignment.ContributionsViewBuilder do
  @moduledoc """
  ViewBuilder for `Systems.Assignment.ContributionsView`.

  The parent view is a thin frame — it composes sub-live-components that
  own their own data and state. This builder decides which sections
  appear (pending is always shown; declined only when there is at least
  one declined contribution; confirmed is always shown) and returns them
  as a `:sections` stack the LiveView iterates.
  """
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Assignment

  def view_model(%Assignment.Model{} = assignment, %{} = assigns) do
    %{
      title: Map.get(assigns, :title, ""),
      sections: sections(assignment, assigns)
    }
  end

  defp sections(%Assignment.Model{} = assignment, _assigns) do
    [
      pending_section(assignment),
      declined_section(assignment),
      confirmed_section(assignment)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp pending_section(assignment) do
    {:pending,
     %{
       module: Assignment.ContributionsPendingView,
       id: "contributions-pending",
       assignment: assignment
     }}
  end

  defp declined_section(assignment) do
    case Assignment.Public.list_declined_contributions(assignment) do
      [] ->
        nil

      _ ->
        {:declined,
         %{
           module: Assignment.ContributionsDeclinedView,
           id: "contributions-declined",
           assignment: assignment
         }}
    end
  end

  defp confirmed_section(assignment) do
    {:confirmed,
     %{
       module: Assignment.ContributionsConfirmedView,
       id: "contributions-confirmed",
       assignment: assignment
     }}
  end
end
