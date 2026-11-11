# `Systems.Payment.Plug`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/payment/_plug.ex#L1)

Caches the raw request body for webhook signature verification.

Used as a custom body_reader for Plug.Parsers. The raw body is stored
in conn.assigns[:raw_body] so it can be used for HMAC verification.

# `cache_body_reader`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
