# `Systems.Account.UserForm`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/account/user_form.ex#L1)

# `auth_module`

# `google_signin`

## Attributes

* `creator?` (`:boolean`) (required)
* `post_signin_action` (`:string`) - Defaults to `nil`.

# `handle_info`

# `password_signin`

## Attributes

* `user_type` (`:atom`) (required)
* `for` (`:any`) - Defaults to `%{}`.
* `status` (`:string`) - Defaults to `""`.
* `post_signup_action` (`:string`) - Defaults to `nil`.

# `password_signup`

## Attributes

* `changeset` (`:map`) (required)
* `panl_privacy_policy_visible` (`:boolean`) - Defaults to `false`.
* `panl_privacy_policy_accepted` (`:boolean`) - Defaults to `false`.
* `next_privacy_policy_accepted` (`:boolean`) - Defaults to `false`.
* `next_privacy_policy_error` (`:string`) - Defaults to `nil`.
* `panl_privacy_policy_error` (`:string`) - Defaults to `nil`.

# `print_auth_roles`

# `surfconext_signin`

# `version`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
