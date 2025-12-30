defmodule Systems.Assignment.CrewPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Frameworks.Concept.LiveContext
  alias Systems.Account
  alias Systems.Assignment
  alias Systems.Consent
  alias Systems.Crew
  alias Systems.Workflow

  def view_model(%{crew: crew, id: assignment_id} = assignment, %{current_user: user} = assigns) do
    language = Assignment.Model.language(assignment)
    apply_language(language)

    # Get user_state from assigns (provided by UserState hook)
    user_state = Map.get(assigns, :user_state, %{})

    # Create context that will be passed to all child views
    # Include language so child views can apply it in their processes
    live_context =
      LiveContext.new(%{
        assignment_id: assignment_id,
        user_id: user.id,
        current_user: user,
        timezone: Map.get(assigns, :timezone),
        panel_info: Map.get(assigns, :panel_info),
        user_state: user_state,
        user_state_namespace: [:assignment, assignment_id, :crew, crew.id],
        language: language
      })

    # Add live_context to assigns for child view builders
    assigns_with_context = Map.put(assigns, :live_context, live_context)

    %{
      view: current_view(assignment, assigns_with_context),
      info: assignment.info,
      crew: crew,
      crew_member: Crew.Public.get_member_unsafe(crew, user),
      user_state: user_state,
      footer: %{
        privacy_text: dgettext("eyra-ui", "privacy.link"),
        terms_text: dgettext("eyra-ui", "terms.link")
      }
    }
  end

  defp apply_language(language) do
    CoreWeb.Live.Hook.Locale.put_locale(language)
  end

  # State machine - determines which view to show based on current state and action
  defp current_view(%{status: status} = assignment, %{current_user: user} = assigns) do
    tester? = Assignment.Public.tester?(assignment, user)
    previous_view = extract_previous_view_module(assigns)
    action = Map.get(assigns, :action)
    user_state = Map.get(assigns, :user_state)

    context = %{
      tester?: tester?,
      previous_view: previous_view,
      action: action,
      user_state: user_state
    }

    cond do
      not (tester? or status == :online) ->
        nil

      is_nil(action) ->
        initial_view(assignment, assigns, context)

      true ->
        next_view(assignment, assigns, context)
    end
  end

  defp next_view(assignment, assigns, %{action: action, tester?: tester?})
       when not is_nil(action) do
    case action do
      :onboarding_continue ->
        consent_or_work_view(assignment, assigns)

      :accept ->
        work_view(assignment, assigns)

      :decline ->
        finished_view(assignment, assigns)

      :retry ->
        consent_or_work_view(assignment, assigns, tester?)

      :work_done ->
        finished_view(assignment, assigns)
    end
  end

  defp initial_view(assignment, assigns, %{user_state: user_state, tester?: tester?}) do
    %{current_user: user} = assigns

    cond do
      not intro_visited?(assignment, user) ->
        intro_view(assignment, assigns)

      not consent_signed?(assignment, user, tester?) ->
        consent_view(assignment, assigns)

      tasks_finished?(assignment, assigns) ->
        finished_view(assignment, assigns)

      not is_nil(user_state) ->
        work_view(assignment, assigns)

      true ->
        nil
    end
  end

  defp consent_or_work_view(assignment, assigns, tester? \\ false) do
    %{current_user: user} = assigns

    if consent_signed?(assignment, user, tester?) do
      work_view(assignment, assigns)
    else
      consent_view(assignment, assigns)
    end
  end

  defp tasks_finished?(assignment, %{current_user: user}) do
    work_items = work_items(assignment, %{current_user: user})
    work_items_finished?(work_items)
  end

  defp consent_signed?(%{consent_agreement: nil}, _user, _tester?), do: true

  defp consent_signed?(%{consent_agreement: consent_agreement}, user, tester?) do
    revision = Consent.Public.latest_revision(consent_agreement, [:signatures])
    signature = Consent.Public.get_signature(consent_agreement, user)

    case {revision, signature, tester?} do
      {_, signature, false} when not is_nil(signature) ->
        # normal flow: consent signed if signature exists
        true

      {%{id: id}, %{revision_id: revision_id}, true} when id == revision_id ->
        # preview flow: consent signed if signature on latest version
        true

      _ ->
        false
    end
  end

  defp intro_visited?(%{id: assignment_id, page_refs: page_refs}, user) do
    intro_page_ref = Enum.find(page_refs, &(&1.key == :assignment_information))

    # Reload user to get fresh visited_pages from database
    fresh_user = Account.Public.get!(user.id)

    is_nil(intro_page_ref) or
      Account.Public.visited?(fresh_user, {:assignment_information, assignment_id})
  end

  defp intro_view(%{id: assignment_id} = _assignment, %{live_context: context} = _assigns) do
    LiveNest.Element.prepare_live_view(
      "onboarding_view_#{assignment_id}",
      Assignment.OnboardingView,
      live_context: context
    )
  end

  defp consent_view(%{id: assignment_id} = _assignment, %{live_context: context} = _assigns) do
    LiveNest.Element.prepare_live_view(
      "onboarding_consent_view_#{assignment_id}",
      Assignment.OnboardingConsentView,
      live_context: context
    )
  end

  defp work_view(%{id: assignment_id} = _assignment, %{live_context: context} = _assigns) do
    LiveNest.Element.prepare_live_view(
      "crew_work_view_#{assignment_id}",
      Assignment.CrewWorkView,
      live_context: context
    )
  end

  defp finished_view(%{id: assignment_id} = _assignment, %{live_context: context} = _assigns) do
    LiveNest.Element.prepare_live_view(
      "finished_view_#{assignment_id}",
      Assignment.FinishedView,
      live_context: context
    )
  end

  defp work_items(%{status: status, crew: crew} = assignment, %{current_user: user}) do
    if Assignment.Public.tester?(assignment, user) or status == :online do
      member = Crew.Public.get_member(crew, user)
      work_items(assignment, member, user)
    else
      []
    end
  end

  defp work_items(%{workflow: workflow} = assignment, %{} = member, %{} = user) do
    ordered_items = Workflow.Model.ordered_items(workflow)
    Enum.map(ordered_items, &{&1, get_or_create_task(&1, assignment, member, user)})
  end

  defp work_items(_assignment, nil, _), do: []

  defp get_or_create_task(item, %{crew: crew} = assignment, member, user) do
    identifier = Assignment.Private.task_identifier(assignment, item, member)

    if task = Crew.Public.get_task(crew, identifier) do
      task
    else
      Crew.Public.create_task!(crew, [user], identifier)
    end
  end

  defp work_items_finished?([]), do: false

  defp work_items_finished?(work_items) do
    task_ids =
      work_items
      |> Enum.reject(fn {_, task} -> task == nil end)
      |> Enum.map(fn {_, task} -> task.id end)

    if Enum.empty?(task_ids) do
      false
    else
      Crew.Public.tasks_finished?(task_ids)
    end
  end

  # Extract previous view module from vm.view (which becomes previous during round trip)
  defp extract_previous_view_module(%{vm: %{view: %{implementation: module}}}), do: module
  defp extract_previous_view_module(_assigns), do: nil
end
