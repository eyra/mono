# `Systems.Affiliate.Public`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/affiliate/_public.ex#L1)

# `count_users`

# `decode_id`

# `deliver_event`

Sends an event that `queue_event/3` queued.

# `get_identifier`

The identifier the affiliate knows the user by, or nil.

# `get_redirect_url`

# `get_user`

# `get_user`

# `get_user_info`

# `list_user_ids`

# `obtain_user`

# `obtain_user!`

# `obtain_user_info`

# `obtain_user_info!`

# `prepare_affiliate`

# `prepare_affiliate_user`

# `prepare_user`

# `prepare_user_info`

# `queue_event`

Queues `event` for the affiliate's callback URL (`Affiliate.CallbackWorker`).
Inside a transaction the callback is sent only after it commits. `affiliate`
is the affiliate or a struct that has one, such as an assignment.

# `recruit_url_for_resource`

# `redirect_url`

# `register_user!`

# `send_event`

# `url_for_resource`

# `validate_url`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
