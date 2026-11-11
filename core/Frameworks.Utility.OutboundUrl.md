# `Frameworks.Utility.OutboundUrl`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/utility/outbound_url.ex#L1)

Requests to URLs that users enter, such as an affiliate's callback URL.

Only `https` URLs on port 443 whose host resolves to public addresses are
allowed: no loopback, private, link-local, CGNAT, multicast, reserved or
cloud metadata addresses, IPv4 or IPv6. `request/5` resolves the host again
and connects to the address it checked, so a name can't resolve to a public
address when the URL is saved and to a private one when it is requested.
TLS still verifies the certificate against the host name. Redirects are
never followed.

Host names are looked up with `:inet_res`, which asks the name servers of
`/etc/resolv.conf` from the caller's own process, not through OTP's native
resolver: that is a small worker pool every lookup on the node shares, so a
name server that never answers would hold a worker after the check gave up.

# `reason`

```elixir
@type reason() ::
  :invalid_url
  | :scheme_not_allowed
  | :port_not_allowed
  | :host_not_found
  | :address_not_allowed
  | :timeout
```

# `check`

```elixir
@spec check(String.t(), keyword()) ::
  {:ok, URI.t(), :inet.ip_address()} | {:error, reason()}
```

Checks that `url` is an `https` URL on port 443 whose host resolves to
public addresses only. A host that doesn't resolve gives
`{:error, :host_not_found}`, and a lookup that takes longer than
`opts[:timeout]` ms (default 5 s) gives `{:error, :timeout}`.
`opts[:resolver]` replaces the DNS lookup, and `opts[:nameservers]`
(`[{address, port}]`) the name servers it asks, for tests.

# `public_address?`

```elixir
@spec public_address?(:inet.ip_address()) :: boolean()
```

True for an address on the public internet. IPv4-mapped, NAT64 and 6to4
IPv6 addresses are judged by the IPv4 address they carry.

# `request`

`:hackney.request/5` to `url` after `check/2`, connected to the checked
address and without following redirects. With `options[:deadline]` (ms) the
DNS lookup and connecting together take at most that long; a lookup that
uses it up gives `{:error, :timeout}`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
