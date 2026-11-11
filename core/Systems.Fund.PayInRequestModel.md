# `Systems.Fund.PayInRequestModel`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/fund/pay_in_request_model.ex#L1)

Form-object for `Fund.Public.create_pay_in/3`. Holds the researcher's
input in the "Add participants" modal: how many participants they want
to fund, at what fee, plus the (persisted) study aim.

Reward is stored in cents. `changeset/2` normalizes the raw display
string (e.g. `"5,00"` / `"5.00"`) to cents before casting.

Cast and validate are split (see `Systems.Content.FileModel`) so the
view can echo the current input on every keystroke without forcing
errors until the researcher hits Confirm.

# `changeset`

# `validate`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
