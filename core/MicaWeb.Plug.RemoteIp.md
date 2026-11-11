# `MicaWeb.Plug.RemoteIp`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/live/hook/remote_ip.ex#L11)

Sets `conn.remote_ip` to the client's address, keeps it in the session as a
string for LiveViews (`MicaWeb.Live.Hook.RemoteIp`), and adds it to the
Logger metadata as `remote_ip`.

A request from a trusted proxy (nginx on the host, or the platform's proxy)
comes from the last address in `X-Forwarded-For` that isn't a trusted proxy,
as such a proxy sets or appends to that header. Other forwarding headers are
ignored, as a proxy passes them on unchanged from the client. A request from
any other address keeps that address.

The trusted proxies are the loopback and private ranges, unless the
`TRUSTED_PROXIES` environment variable lists others (`trusted_proxies!/1`).

# `call`

# `client_ip`

The client's address of a request with `headers` from `peer`, the address
of the connection.

# `init`

# `trusted_proxies!`

Checks the trusted proxies of `TRUSTED_PROXIES`: addresses or CIDR ranges,
IPv4 or IPv6. Raises an `ArgumentError` on an entry that is neither, and on
an empty list: behind a proxy, that would count every client as the proxy.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
