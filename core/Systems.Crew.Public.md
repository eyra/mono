# `Systems.Crew.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/crew/_public.ex#L1)

# `active?`

# `apply_member`

# `apply_member_with_role`

# `auth_module`

# `cancel`

# `cancel`

# `cancel_task`

# `complete_task`

# `complete_task!`

# `completed_tasks`

# `count_members`

# `count_participants`

# `count_participants_finished`

# `count_pending_tasks`

# `count_tasks`

# `create_task`

# `create_task!`

# `delete_task`

# `ensure_member_with_role`

Makes the user an active member of the crew with the given role. Safe to call
repeatedly and concurrently: existing rows are kept as they are.

# `expire_member`

# `expire_tasks_by_template`

Expires all tasks of the crew whose identifier contains every element of
`task_template`. Returns the number of expired tasks.

# `expired_member?`

# `expired_pending_started_tasks`

# `finished?`

# `get!`

# `get_expired_member`

# `get_member`

# `get_member!`

# `get_member_including_expired`

# `get_task`

# `get_task!`

# `list`

# `list_members`

# `list_tasks`

# `list_tasks_for_user`

# `mark_expired`

  Marks members & tasks as expired when:
  - expire_at is in the past
  - started_at is nil

# `mark_expired_debug`

# `member`

# `member?`

# `multi_update`

# `multi_update`

# `pending_tasks_query`

# `prepare`

# `print_auth_roles`

# `public_id`

# `reset_member`

# `reset_member`

Resets an (expired) member and revives its expired tasks.

Pass `revive?:`, a function that gets each expired task, to revive only the
tasks it returns true for; the others stay expired.

# `reset_member!`

# `start_task`

# `started?`

# `subject`

# `task_status_counts_by_user`

Returns a `%{user_id => count}` map of tasks in `status_list` on the
given crew, grouped by the task's owner. Non-expired tasks only.
Missing keys mean zero.

# `tasks_finished?`

# `update_task`

# `user_finished?`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
