# Green Light

The Green Light framework is an authorization system that has the following goals:

- Secure by default: deny by default, require explicit authorizations grants
- Rely on automation, not discipline
- Clear auditing (understandable by stakeholders)
- Defense in depth: limit impact of security flaws by having several layers of protection

The authorization system is comprised of several parts that work together to
provide this functionality. At the core of the system there is Role Based Access
Control (RBAC).

## Terminology

This system makes use of the following terminology.

### Permission

A permission is a unique operation in the system. The application code that
needs protection only works in terms of permissions. It is up to the
authorization system to determine if the current user has the required
permission.

### Entity

Anything that can be accessed. The concrete implementation of this concept is an Ecto struct.

### Principal

The principal is another name for user. It is given a distinct name since it can
also be used to represent other authenticated systems. An example of this is an
authorized application that acts on a users behalf. By making this a distinct
concept it allows those kind of applications to operate with a subset of
permissions.

### Role

A role is an Elixir atom that maps on to a set of permissions.

### Permission Map

The permission map (`Frameworks.GreenLight.PermissionMap`) is the datastructure
which is used to map roles to permissions.

### Role Assignment

A role assignment (`Frameworks.GreenLight.RoleAssignment`) registers the assignment
of a role to a principal on a specific entity. This is what makes having local
roles possible.

## Plug Middleware

### Entity Loaders

The `Frameworks.GreenLight.Plug` authorization module needs entities to enforce it's access rules. The entity loaders are responsible for taking Plug `path_param` and returning the entities.

### Authorization

The `Frameworks.GreenLight.Plug` automatically enforces permission checks for all
controller actions.

## Phoenix Integration

Phoenix integration is available to make usage of the authorization system convenient.

### Controller Action Access Management

All Phoenix controllers are automatically protected by the Plug middleware.
Access to actions is denied unless a principal has sufficient roles to access
the action. Each action is a seperate permission. Without a mapping of
permissions to roles all access is denied.

The `Frameworks.GreenLight.Permissions.grant_actions/2` helper macro is provided to setup
such a mapping.

### View Helpers

The Phoenix views are extended with the `Frameworks.GreenLight.can?/3`
helper. This allows for easy checking of permissions within a temlate.

## Mix Tasks

The system comes with several mix tasks to inspect the state of the
authorization system.

### Permissions

The `mix grlt.perms` task shows a table of all permissions that have been
defined with their associated roles. All permissions and roles are sorted
alphabetically.
