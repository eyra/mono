defmodule Systems.Assignment.CrewPageBuilder do
  use Gettext, backend: CoreWeb.Gettext

  alias Systems.{
    Assignment,
    Crew,
    Workflow,
    Consent,
    Account,
    Affiliate
  }

  def view_model(%{crew: crew} = assignment, %{current_user: user} = assigns) do
    apply_language(assignment)

    %{
      view: current_view(assignment, assigns),
      info: assignment.info,
      crew: crew,
      crew_member: Crew.Public.get_member_unsafe(crew, user),
      footer: %{
        privacy_text: dgettext("eyra-ui", "privacy.link"),
        terms_text: dgettext("eyra-ui", "terms.link")
      }
    }
  end

  defp apply_language(assignment) do
    assignment
    |> Assignment.Model.language()
    |> CoreWeb.Live.Hook.Locale.put_locale()
  end

  # State machine - determines which view to show based on current state
  defp current_view(%{status: status} = assignment, %{current_user: user} = assigns) do
    tester? = Assignment.Public.tester?(assignment, user)
    previous_view = extract_previous_view_module(assigns)

    if tester? or status == :online do
      cond do
        # If returning from finished view and consent declined, show consent again
        previous_view == Assignment.FinishedView and declined_consent?(assignment, user) ->
          consent_view(assignment, assigns, tester?)

        tasks_finished?(assignment, user) ->
          finished_view(assignment, assigns)

        declined_consent?(assignment, user) ->
          finished_view(assignment, assigns)

        not consent_signed?(assignment, user, tester?) ->
          consent_view(assignment, assigns, tester?)

        not intro_visited?(assignment, user) ->
          intro_view(assignment, assigns)

        true ->
          work_view(assignment, assigns, tester?)
      end
    else
      # Assignment not online and user is not a tester - no view
      nil
    end
  end

  # State checks
  defp declined_consent?(assignment, user) do
    Assignment.Private.declined_consent?(assignment, user.id)
  end

  defp tasks_finished?(assignment, user) do
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

    is_nil(intro_page_ref) or
      Account.Public.visited?(user, {:assignment_information, assignment_id})
  end

  defp intro_view(
         %{page_refs: page_refs},
         %{current_user: user, fabric: fabric}
       ) do
    intro_page_ref = Enum.find(page_refs, &(&1.key == :assignment_information))

    Fabric.prepare_child(fabric, :current_view, Assignment.OnboardingView, %{
      page_ref: intro_page_ref,
      title: dgettext("eyra-assignment", "onboarding.intro.title"),
      user: user
    })
  end

  defp consent_view(
         %{consent_agreement: consent_agreement},
         %{current_user: user, fabric: fabric},
         _tester?
       ) do
    revision = Consent.Public.latest_revision(consent_agreement, [:signatures])

    Fabric.prepare_child(
      fabric,
      :current_view,
      Assignment.OnboardingConsentView,
      %{
        revision: revision,
        user: user
      }
    )
  end

  defp work_view(
         %{
           privacy_doc: privacy_doc,
           consent_agreement: consent_agreement,
           page_refs: page_refs,
           crew: crew
         } = assignment,
         %{
           fabric: fabric,
           current_user: user,
           timezone: timezone,
           session: session
         } = assigns,
         tester?
       ) do
    panel_info = Map.get(session, "panel_info")
    work_items = work_items(assignment, assigns)
    context_menu_items = context_menu_items(assignment, assigns)

    intro_page_ref = Enum.find(page_refs, &(&1.key == :assignment_information))
    support_page_ref = Enum.find(page_refs, &(&1.key == :assignment_helpdesk))

    Fabric.prepare_child(fabric, :current_view, Assignment.CrewWorkView, %{
      work_items: work_items,
      privacy_doc: privacy_doc,
      consent_agreement: consent_agreement,
      context_menu_items: context_menu_items,
      intro_page_ref: intro_page_ref,
      support_page_ref: support_page_ref,
      crew: crew,
      user: user,
      timezone: timezone,
      panel_info: panel_info,
      tester?: tester?
    })
  end

  defp finished_view(
         %{affiliate: affiliate} = assignment,
         %{fabric: fabric, current_user: user}
       ) do
    declined? = Assignment.Private.declined_consent?(assignment, user.id)

    redirect_url =
      case Affiliate.Public.redirect_url(affiliate, user) do
        {:ok, url} -> url
        {:error, _} -> nil
      end

    title =
      if declined? do
        dgettext("eyra-assignment", "finished_view.title.declined")
      else
        dgettext("eyra-assignment", "finished_view.title")
      end

    body =
      cond do
        declined? and redirect_url ->
          dgettext("eyra-assignment", "finished_view.body.declined.redirect")

        declined? ->
          dgettext("eyra-assignment", "finished_view.body.declined")

        redirect_url ->
          dgettext("eyra-assignment", "finished_view.body.redirect")

        true ->
          dgettext("eyra-assignment", "finished_view.body")
      end

    show_illustration = not declined? and is_nil(redirect_url)

    retry_button = %{
      action: %{type: :send, event: "retry"},
      face: %{
        type: :plain,
        icon: :back,
        icon_align: :left,
        label: dgettext("eyra-assignment", "back.button")
      }
    }

    redirect_button =
      if redirect_url do
        %{
          action: %{type: :http_get, to: redirect_url},
          face: %{
            type: :primary,
            label: dgettext("eyra-assignment", "redirect.button")
          }
        }
      else
        nil
      end

    Fabric.prepare_child(fabric, :current_view, Assignment.FinishedView, %{
      title: title,
      body: body,
      show_illustration: show_illustration,
      retry_button: retry_button,
      redirect_button: redirect_button
    })
  end

  defp context_menu_items(assignment, _assigns) do
    [:assignment_information, :privacy, :consent, :assignment_helpdesk]
    |> Enum.map(&context_menu_item(&1, assignment))
    |> Enum.filter(&(not is_nil(&1)))
  end

  defp context_menu_item(:privacy = key, %{privacy_doc: privacy_doc}) do
    if privacy_doc do
      %{
        id: key,
        label: dgettext("eyra-assignment", "context.menu.privacy.title"),
        url: privacy_doc.ref
      }
    else
      nil
    end
  end

  defp context_menu_item(:consent = key, %{consent_agreement: consent_agreement}) do
    if consent_agreement do
      %{id: key, label: dgettext("eyra-assignment", "context.menu.consent.title")}
    else
      nil
    end
  end

  defp context_menu_item(:assignment_information = key, %{page_refs: page_refs}) do
    if Enum.find(page_refs, &(&1.key == :assignment_information)) != nil do
      %{id: key, label: dgettext("eyra-assignment", "context.menu.information.title")}
    else
      nil
    end
  end

  defp context_menu_item(:assignment_helpdesk = key, %{page_refs: page_refs}) do
    if Enum.find(page_refs, &(&1.key == key)) != nil do
      %{id: key, label: dgettext("eyra-assignment", "context.menu.support.title")}
    else
      nil
    end
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

  # Extract previous view module using pattern matching
  defp extract_previous_view_module(%{
         vm: %{view: %Fabric.LiveComponent.Model{ref: %{module: module}}}
       }),
       do: module

  defp extract_previous_view_module(%{vm: %{view: %{module: module}}}), do: module
  defp extract_previous_view_module(_assigns), do: nil
end
