# `Systems.Admin.AccountViewBuilder`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/admin/account_view_builder.ex#L1)

ViewBuilder for the Admin AccountView.

Builds the view model for user account management including:
- User list with filtering and search
- User action buttons (verify, activate, etc.)

The user list is capped at @max_users; user_count reflects the
unfiltered match count so admins can tell when results were trimmed.

The matching itself is `Systems.Admin.Public.list_matching_users/2`.

# `build_user_item`

Builds the view-model item for a single user. Public for direct testing.

# `build_user_items`

Builds the (uncapped) list of user items with filters and search query
applied. Kept public to support direct testing of filter behaviour.

# `view_model`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
