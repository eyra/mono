# `Systems.Assignment.Private`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/assignment/_private.ex#L1)

# `allowed_external_panel_ids`

# `clear_performance_event`

# `connection_title`

# `connection_view_module`

# `connector_popup_module`

# `done_button?`

Whether the participant sees the "Next, I am done" button. Only the vertical
task list has it; the horizontal list finishes after its last task. The done
screen shows Back exactly then, so the participant can undo the click.

# `ensure_affiliate`

# `ensure_affiliate!`

# `finished_logged?`

Whether the Monitor has the member's finished event for the assignment, which every
`{:crew_member, :finished_tasks}` logs (testers excepted).

# `get_crew_member`

# `get_preview_url`

# `get_template`

# `get_workflow_item`

The workflow item of a crew task. Returns `{:error, :not_found}` when the item
has been deleted, which leaves its tasks orphaned.

# `log_performance_event`

# `log_performance_event`

# `member_id`

# `no_consent?`

True when the participant has to give consent and hasn't. Nobody has to consent
again: a signature on any revision counts. Whoever joined while consent was off
is never asked.

# `page_body_default`

# `page_title_default`

# `queue_progress_event`

# `reward_idempotence_key`

# `reward_idempotence_key`

# `runtime_config`

# `slugify`

# `storage_endpoint_key`

# `task_identifier`

# `task_template`

# `task_view`

Which task view the participant gets: none without tasks, the single task
view for one task, and for more the task list the template chose: the
vertical `:list` or the `:horizontal_list`.

# `workflow_item_id`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
