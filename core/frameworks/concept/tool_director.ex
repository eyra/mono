defmodule Frameworks.Concept.ToolDirector do
  @type user :: map()
  @type tool :: map()
  @type public_id :: binary()
  @type subject :: {member, list(task)}
  @type task :: map()
  @type member :: map()
  @type user_ref :: user | public_id
  @type authorization_context :: nil | struct()

  @callback apply_member_and_activate_task(tool, user) :: task | nil
  @callback search_subject(tool, user_ref) :: subject | nil
  @callback assign_tester_role(tool, user) :: :ok | :error
  @callback authorization_context(tool, user) :: authorization_context
end
