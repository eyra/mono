# `Systems.Assignment.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/_public.ex#L1)

The assignment context.

# `accept_member`

# `accept_participation`

Marks a participation as accepted — the owner confirmed the contribution.
Sets `accepted_at`, approves the associated reward (which triggers
payout) if any, and dispatches `{:assignment_participation, :accepted}`.
All in one transaction. Idempotent on `accepted_at`.

Returns `{:error, :participation_already_rejected}` when the
participation was previously rejected. Business rule: rejection
reopens the assignment spot for a new participant, so accepting
after a rejection would double-book. Any dispute resolution happens
outside the system.

# `add_participant!`

# `apply_member`

# `assign_tester_role`

# `attention_list_enabled?`

# `auth_module`

# `cancel`

# `complete_participation`

# `complete_participation`

Marks a participation as complete — the participant has submitted their
work (either by finishing the last task, or by explicitly clicking "I'm
done"). Sets `completed_at`, flips the associated reward to
`:pending_approval` (if any), and dispatches
`{:assignment_participation, :completed}`. All three happen in one
transaction; a failure anywhere rolls the whole thing back.

Idempotent on `completed_at`: a second call is a no-op.

Downstream housekeeping (owner next-action, view refreshes) lives in
`Assignment.Switch` and runs after the transaction commits.

# `complete_task`

# `copy`

# `copy_info`

# `copy_workflow`

# `count_participants`

# `count_participants_finished`

# `create_page_ref`

# `delete_consent_agreement`

# `delete_page_ref`

# `delete_storage_endpoint!`

# `ensure_tester`

Makes the user a tester of the assignment: a crew member with the tester role,
so that previewing the study shows its tasks. Safe to call repeatedly and
concurrently.

# `exclude`

# `excluded?`

  Is user excluded? from joining given assignment

# `expiration_timestamp`

# `expire_member`

# `expired_user_assignments`

# `funded?`

A "funded" assignment has a fund AND at least one pay-in on that fund.
The fund alone doesn't qualify — every assignment gets an empty fund
at assembly time (`_assembly.ex`), so fund-existence is not a signal
that money is actually involved.

# `get`

# `get!`

# `get_by`

# `get_by`

# `get_by_content_page`

# `get_by_tool`

# `get_by_tool_ref`

# `get_by_workflow_item_id`

# `get_crew`

# `get_member_by_task`

# `get_participation`

# `get_reward`

# `get_task`

# `get_workflow!`

# `has_budget_capacity?`

Returns true when the assignment's fund can cover at least one more
participant's reward. Free assignments and virtual currencies always pass;
a paid assignment without a resolvable legal-currency fund never passes.

The available balance already excludes rewards reserved for in-flight
participants: reserving a reward debits the fund's available account (and
credits the reserve account), so `Fund.Model.amount_available/1` reflects
only the genuinely unreserved balance.

# `has_open_spots?`

# `include`

# `list_accepted_participations`

Participations that have been accepted by the owner — the "confirmed"
section. Most-recently-accepted first.

# `list_by_crew`

# `list_by_participant`

# `list_participants`

  Lists the participants of the assignment.
  Returns a list of maps with the following keys:
  * `user_id`
  * `public_id`
  * `external_id`
  * `member_id`

# `list_participations`

# `list_pending_participations`

Participations that have been submitted but not yet reviewed — the
"pending" section of the Contributions tab. Ordered oldest-first so the
reviewer works through them FIFO.

# `list_rejected_participations`

Participations that have been rejected by the owner — the "declined"
section. Most-recently-rejected first.

# `list_signatures`

# `list_tasks`

# `list_user_ids`

# `mark_expired_debug`

# `member?`

# `obtain_participation`

# `obtain_participation!`

# `open_spot_count`

How many new members can be added to the assignment?

# `owner!`

# `owners`

Users with `:owner` inherited on this assignment — typically the owner(s)
of the containing project. Assignment auth nodes rarely carry direct owner
assignments; inheritance is via the project node.

# `participant_id`

# `participant_identifier`

The id a crew member is known by in the assignment's data, as in the participant
export: their identifier at the assignment's affiliate, else their crew member id.
Returns `:error` when the user is not a member of the crew.

# `prepare`

# `prepare_info`

# `prepare_page_ref`

# `prepare_page_refs`

# `prepare_participation`

# `prepare_tool_ref`

# `prepare_workflow`

# `prepare_workflow_item`

# `prepare_workflow_items`

# `print_auth_roles`

# `query_by_tool`

# `query_by_tool_ref`

# `ready?`

# `reject_participation`

Marks a participation as rejected — the owner declined the contribution.
Sets `rejected_at` + `rejected_message` and rejects the associated reward
(rolling the deposit back into the fund) if any, and dispatches
`{:assignment_participation, :rejected}`. All in one transaction.
Idempotent on `rejected_at`.

Returns `{:error, :participation_already_accepted}` when the
participation was previously accepted. Business rule: once accepted
the reward has been approved and paid out; reversing that requires
admin intervention at the Fund layer, not a routine reject.

# `reset_member`

# `reset_opts`

Options for resetting a member of the assignment's crew. Tasks of deleted
workflow items are expired and must stay expired when the member is reset,
otherwise the participant can never finish again.

# `rewarded_amount`

# `rollback_deposit`

# `rollback_expired_deposits`

# `rollback_expired_deposits`

# `run_apply_member`

# `search_subject`

# `start_task`

# `start_task`

# `status`

# `task_labels`

# `tester?`

# `timestamp`

# `timestamp`

# `update`

# `update!`

# `update_consent_agreement`

# `update_fund`

# `update_storage_endpoint`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
