# `Systems.Org.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/org/_public.ex#L1)

# `add_member`

Assigns the :member role to a user for the given organisation.
Auth roles are the source of truth for membership (Option C pattern).

# `add_user`

# `archive`

Archives an organisation node.

# `assign_owner`

Assigns the :owner role to a user for the given organisation and
immediately syncs the AddDomainMembers NextAction so the new owner
sees outstanding domain-matched users on their next admin visit
without waiting for a registration event.

# `auth_module`

# `can_manage?`

Returns true when the user is allowed to manage the given organisation
(members, settings, domain-matched actions). Mirrors the access rule
used by the UI: system admins can manage any org; org owners can
manage their own.

Use this at event-handler boundaries to defend against stale LiveView
sessions where a user's role was revoked while the page was still open.

# `clear_domain_match_next_action`

Clears the AddDomainMembers NextAction for a user on a given org.
Used when revoking the :owner role so the action disappears
immediately instead of lingering until the next sync pass.

# `create_link!`

# `create_node`

# `create_node!`

# `create_node!`

# `delete_user`

# `find_domain_matched_users`

Finds platform users whose email matches org domains but aren't already members.
Returns users that could be suggested for membership based on email domain matching.

# `get_link`

# `get_node`

# `get_node!`

# `list_all_nodes`

Lists all nodes including archived ones. Use sparingly.

# `list_archived_nodes`

Lists only archived organisation nodes.

# `list_members`

Lists all users with the :member role for the given organisation.
Auth roles are the source of truth for membership (Option C pattern).

# `list_members_with_added_at`

Like `list_members/1` but returns `{user, added_at}` tuples where
`added_at` is the timestamp at which the `:member` role was granted on
the org's auth_node. Used by the Members tab to power the "Recent"
filter.

# `list_nodes`

# `list_nodes`

# `list_orgs`

Lists all organisations where the user has the :owner role.

# `list_owners`

Lists all users with the :owner role for the given organisation.

# `member?`

Checks if a user is a member of the given organisation.

# `owns_any?`

Checks if the user owns any organisations.

# `print_auth_roles`

# `remove_member`

Revokes the :member role from a user for the given organisation.
Auth roles are the source of truth for membership (Option C pattern).

# `restore`

Restores an archived organisation node.

# `revoke_owner`

Revokes the :owner role from a user for the given organisation and
clears their AddDomainMembers NextAction for this org, since they
are no longer responsible for adding domain-matched members here.

# `sync_all_domain_match_next_actions`

Syncs NextActions for a specific user across relevant orgs.
For system admins: syncs all orgs.
For org owners: syncs only orgs they own.
Used as a fallback when opening admin pages.

# `sync_domain_match_next_action`

Syncs the NextAction for domain-matched users.
Creates the action if domain-matched users exist, clears it otherwise.

# `sync_next_actions_for_new_user`

Syncs NextActions for all org owners when a new user registers.
Finds orgs whose domains match the user's email and notifies their owners.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
