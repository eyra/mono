defmodule Systems.Assignment.OnboardingViewBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.Content

  def view_model(%{page_refs: page_refs, id: assignment_id} = _assignment, %{current_user: user}) do
    intro_page_ref = Enum.find(page_refs, &(&1.key == :assignment_information))
    title = dgettext("eyra-assignment", "onboarding.intro.title")

    %{
      page_ref: Map.put(intro_page_ref || %{}, :assignment_id, assignment_id),
      user: user,
      content_page: content_page(intro_page_ref, title),
      continue_button: continue_button()
    }
  end

  defp content_page(nil, _title), do: nil

  defp content_page(page_ref, title) do
    %{
      module: Content.PageView,
      id: :content_page,
      title: title,
      page: page_ref.page
    }
  end

  defp continue_button do
    %{
      action: %{type: :send, event: "continue"},
      face: %{
        type: :primary,
        label: dgettext("eyra-assignment", "onboarding.continue.button")
      }
    }
  end
end
