defmodule CoreWeb.Features.PayoutFlowTest do
  @moduledoc """
  Broad journey test for the payout flow: participant earns a reward,
  researcher approves it, participant requests payout.

  Walks steps 2-5 of `test/e2e/request_payout.spec.ts` (UC-OPP-06) through
  the UI, exercising the cross-system signal chain that narrow tests
  (`fund_assignment_test`, `approve_reward_test`, `request_payout_test`)
  Factory-skip:

    * task-complete signal → Fund.Public.mark_pending_approval/1 →
      reward `:reserved` → `:pending_approval`
    * approve-task signal (from PayoutModal "Pay out all") →
      Fund.Public.approve_reward/1 → reward `:pending_approval` →
      `:approved`

  Step 1 (researcher funds the assignment) is covered by
  `fund_assignment_test.exs`; here we build the funded state via
  Factories so the journey under test starts from a known precondition.

  Justification for this broad test on top of the three narrow ones:
  see `test/features/CLAUDE.md` → "When to add a broad journey test on
  top of narrow ones." All three conditions hold for this flow.
  """

  use CoreWeb.FeatureCase

  import Mox

  alias Systems.Assignment
  alias Systems.Fund
  alias Systems.Manual
  alias Systems.Payment.ProviderMock
  alias Systems.Project

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    Factories.insert!(:currency_ledger, %{currency: :EUR})
    :ok
  end

  @sessions 2
  @tag :feature
  feature "participant earns reward, researcher approves, participant requests payout",
          %{sessions: [researcher_session, participant_session]} do
    merchant_uid = "m_journey_test"

    # Bank-not-verified — drives the `{:error, {:kyc_required, :bank, _}}`
    # branch of Fund.Public.prepare_payout/1 at the end of the journey.
    ProviderMock
    |> stub(:get_merchant, fn ^merchant_uid ->
      {:ok,
       %{
         uid: merchant_uid,
         status: "pending",
         kyc_level: 0,
         compliance_status: "unverified",
         overview_url: nil
       }}
    end)
    |> stub(:list_bank_accounts, fn ^merchant_uid ->
      {:ok, [%{uid: "ba_test", status: "new", verification_url: "https://opp.test/ba/verify"}]}
    end)

    researcher_password = Factories.valid_user_password()
    participant_password = Factories.valid_user_password()

    researcher =
      Factories.insert!(:member, %{
        password: researcher_password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: true
      })

    participant =
      Factories.insert!(:member, %{
        password: participant_password,
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        creator: false,
        merchant_uid: merchant_uid
      })

    # Assignment with a single-chapter, single-page Manual as the workflow
    # tool — simplest tool that the participant can complete entirely via
    # in-app UI clicks (no external URL).
    tool_auth_node = Factories.insert!(:auth_node)
    manual_tool = Manual.Factories.create_manual_tool(1, 1, tool_auth_node)

    workflow = Factories.insert!(:workflow)
    tool_ref = Factories.insert!(:tool_ref, %{manual_tool: manual_tool})

    _workflow_item =
      Factories.insert!(:workflow_item, %{
        workflow: workflow,
        tool_ref: tool_ref,
        title: "Manual task",
        position: 0
      })

    crew = Factories.insert!(:crew)
    auth_node = Factories.insert!(:auth_node)
    info = Factories.insert!(:assignment_info, %{subject_count: 10, subject_reward: 500})

    currency = Factories.insert!(:currency, %{name: "eur_journey"})
    fund = Fund.Factories.create_fund("journey_fund", currency)

    assignment =
      Factories.insert!(:assignment, %{
        info: info,
        workflow: workflow,
        crew: crew,
        auth_node: auth_node,
        fund: fund,
        status: :online,
        special: :questionnaire
      })

    # Wrap in project hierarchy so the LV's branch resolution succeeds when
    # the researcher visits /assignment/X/content (otherwise
    # ContentPageBuilder.view_model/2 crashes on a nil branch).
    assignment
    |> Project.Factories.build_item()
    |> Project.Factories.build_node()
    |> Project.Factories.build_project()
    |> Core.Repo.insert!()

    # Researcher is owner of the assignment so they can navigate to the
    # participants tab + open PayoutModal.
    Factories.insert!(:role_assignment, %{
      node: auth_node,
      role: :owner,
      principal_id: researcher.id
    })

    # Participant joins via the production helper — same as the affiliate
    # flow. Creates a crew member with :participant role AND a reward in
    # :reserved state. The state transitions we want to verify:
    #   :reserved -> :pending_approval  (participant completes task)
    #   :pending_approval -> :approved  (researcher approves via PayoutModal)
    {:ok, _} = Assignment.Public.add_participant!(assignment, participant)

    # ========================================================================
    # Participant — completes the Manual task → reward :reserved
    #                                            → :pending_approval
    # ========================================================================

    participant_session
    |> visit("/user/signin")
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: participant.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: participant_password)
    |> click(Query.css("[data-testid='signin-submit-button']"))
    |> visit("/assignment/#{assignment.id}")
    |> assert_has(Query.css("[data-testid^='chapter-list-item-']"))
    |> click(Query.css("[data-testid^='chapter-list-item-']"))
    |> assert_has(Query.css("[data-testid='manual-chapter-done-button']"))
    |> click(Query.css("[data-testid='manual-chapter-done-button']"))
    |> assert_has(Query.css("[data-testid='finished-view']"))

    # ========================================================================
    # Researcher — sees pending-approvals banner, opens PayoutModal,
    #              clicks "Pay out all" → reward :pending_approval -> :approved
    # ========================================================================

    researcher_session
    |> visit("/user/signin?tab=creator")
    |> fill_in(Query.css("[data-testid='signin-email-input']"), with: researcher.email)
    |> fill_in(Query.css("[data-testid='signin-password-input']"), with: researcher_password)
    |> click(Query.css("[data-testid='signin-submit-button']"))
    |> visit("/assignment/#{assignment.id}/content?tab=participants")
    |> assert_has(Query.css("[data-testid='pending-approvals-cta']"))
    |> click(Query.css("[data-testid='pending-approvals-cta']"))
    |> assert_has(Query.css("[data-testid='payout-modal']"))
    |> click(Query.css("[data-testid='pay-out-all-button']"))
    |> assert_has(Query.css("[data-testid='payout-empty']"))

    # ========================================================================
    # Participant — sees approved balance on home, clicks "Pay out",
    #               KYC handoff modal appears (UC-OPP-06.A1)
    # ========================================================================

    participant_session
    |> visit("/")
    |> assert_has(Query.css("[data-testid='payout-button']"))
    |> click(Query.css("[data-testid='payout-button']"))
    |> assert_has(Query.css("[data-testid='confirmation-modal-confirm-button']"))
  end
end
