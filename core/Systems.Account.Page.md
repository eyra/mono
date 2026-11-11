# `Systems.Account.Page`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/page.ex#L1)

The Account page (`/user/account`).

Renders inside the workspace layout for creators and the stripped
layout (same as the auth and onboarding pages) for participants —
`Account.PageBuilder` decides which, and which menu set to use,
based on the current user.

Within the chosen layout the body is an adaptable_layout: a single
pane for users with one tab (the common case) and a tabbar for users
with two or more (PANL participants get a Features tab). The Profile
tab owns the Sign-out action.

# `auth_module`

# `consume_event`

# `handle_close_modal`

# `handle_consumed_event`

# `handle_hide_modal`

# `handle_info`

# `handle_present_modal`

# `handle_resize`

# `hide_modal`

# `observe_view_model`

# `present_modal`

# `print_auth_roles`

# `put_info_flash`

# `put_saved_info_flash`

# `put_updated_info_flash`

# `update_actions`

# `update_menus`

# `update_menus`

# `update_view_model`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
