# Architectural Guideline: Authorization vs. Grouping (Option C)

## Summary

**Auth roles are the single source of truth for entity membership.** Only add dedicated join tables when additional metadata is required that cannot be stored in role assignments.

## The Problem

Many systems need to track "which users belong to which entity" (e.g., organisation members, crew participants). There are two common approaches:

1. **Dedicated join tables** (e.g., `org_users`, `crew_members`)
2. **Authorization roles** (via `authorization_role_assignments`)

Using both simultaneously creates **sync issues** - the two sources of truth can drift apart.

## The Solution: Option C

### Decision Framework

| Question | If Yes | If No |
|----------|--------|-------|
| Is this a membership/grouping relationship? | Use auth roles | Use regular FK/join table |
| Does the relationship need metadata (timestamps, status, IDs)? | Add extension table | Auth roles only |
| Is authorization needed for the entity? | Auth roles are natural fit | Consider if auth still simplifies queries |

### The Three Layers

#### 1. Auth Layer (Required)
Role assignments on auth_node - **source of truth for membership**

```elixir
# Assign membership
Core.Authorization.assign_role(user, entity.auth_node, :member)

# Query members
Core.Authorization.list_principals_with_role(entity.auth_node, :member)
```

Benefits:
- Automatically provides authorization semantics
- Single source of truth
- Consistent pattern across all systems

#### 2. Extension Layer (Optional)
Metadata-only tables for data that cannot live in role_assignments

**When to use:**
- Anonymous identifiers (e.g., `public_id` for privacy)
- Expiration tracking (e.g., `expire_at`, `expired`)
- External system IDs (e.g., `external_id`)

**Critical rule:** These tables do NOT define membership, they extend it.

```elixir
# crew_member_data table (extension only)
schema "crew_member_data" do
  belongs_to :user, User
  belongs_to :crew, Crew
  field :public_id, :integer  # Cannot be derived from user_id
  field :expire_at, :utc_datetime
  field :expired, :boolean
end
```

#### 3. Reference Layer (Optional)
Foreign keys for performance when you need direct DB joins

**When to use:**
- Performance-critical queries that can't use auth layer efficiently
- Always derived from auth layer, never authoritative

## Examples

### Organisation Members (Auth-Only)

```elixir
# In Org.Public

def list_members(%Node{auth_node: auth_node}) do
  Core.Authorization.list_principals_with_role(auth_node, :member)
  |> Repo.preload([:profile])
end

def add_member(%Node{auth_node: auth_node}, %User{} = user) do
  Core.Authorization.assign_role(user, auth_node, :member)
end

def remove_member(%Node{auth_node: auth_node}, %User{} = user) do
  Core.Authorization.revoke_role(user, auth_node, :member)
end
```

No `org_users` table needed for membership.

### Crew Members (Auth + Extension)

```elixir
# Auth layer for membership
Core.Authorization.assign_role(user, crew.auth_node, :participant)

# Extension layer for metadata (public_id cannot be derived)
%CrewMemberData{
  user_id: user.id,
  crew_id: crew.id,
  public_id: next_public_id(crew)  # Auto-incremented anonymous ID
}
```

The `crew_member_data` table exists only because `public_id` cannot be stored in role_assignments.

### Projects (Auth-Only, Existing Pattern)

Projects already follow Option C - they use auth roles only, no `project_users` table.

```elixir
# Authorization check via auth_node
can_access?(user, project.auth_node, :owner)
```

## Role Naming Convention

There are two types of roles in the system:

### System-Level Roles (from Principal Protocol)
Assigned automatically based on user state, not stored in DB:

| Role | Meaning |
|------|---------|
| `:visitor` | Unauthenticated user |
| `:user` | Authenticated user |
| `:creator` | User with creator flag |
| `:admin` | User listed in admin config |

### Entity-Level Roles (from RoleAssignment)
Stored in `authorization_role_assignments`, assigned per auth_node:

| Role | Meaning |
|------|---------|
| `:owner` | Full control of entity |
| `:member` | Member of entity (organisation, etc.) |
| `:participant` | Participant in entity (crew, assignment) |
| `:tester` | Tester access to entity |

The `:member` role is specifically for entity membership (not to be confused with the old system-level `:member` which was renamed to `:user`).

## Implementation Checklist

When implementing a new user-entity relationship:

1. **Does the entity need an auth_node?**
   - If users need authorization to access/modify the entity: Yes
   - Add `belongs_to :auth_node, Core.Authorization.Node` to the model

2. **What role(s) are needed?**
   - Define roles in `lib/core/authorization.ex` if new
   - Common roles: `:owner`, `:member`, `:participant`, `:admin`

3. **Is metadata needed beyond membership?**
   - If no: Use auth roles only
   - If yes: Create an extension table (named `*_data` to clarify purpose)

4. **Add helper functions to Public API:**
   ```elixir
   def add_member(entity, user)
   def remove_member(entity, user)
   def list_members(entity)
   def member?(entity, user)
   ```

## Migration Path for Existing Systems

For systems that currently use both auth roles and join tables:

1. **Identify the source of truth** - Usually the join table has been authoritative
2. **Ensure auth roles exist for all members** - Migration script to sync
3. **Update queries to use auth layer** - Replace join table queries
4. **Deprecate join table for membership** - Keep only if needed for metadata
5. **Rename to `*_data` if keeping** - Clarifies it's an extension, not source of truth

## Key Benefits

1. **Single source of truth** - No sync issues between tables
2. **Automatic authorization** - Membership implies access rights
3. **Consistent patterns** - Same approach across all systems
4. **Extensible** - Add metadata when needed without changing membership semantics
5. **Queryable** - Auth layer provides efficient membership queries

## Related Files

- `lib/core/authorization.ex` - Authorization module with role functions
- `lib/core/authorization/node.ex` - Auth node schema
- `lib/core/authorization/role_assignment.ex` - Role assignment schema
