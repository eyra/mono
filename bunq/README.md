# Bunq


We use asymmetric cryptography for signing requests and encryption.
The client (you) and the server (bunq) must have a pair of keys: a private key and a public key. You need to pre-generate your own pair of 2048-bit RSA keys in the PEM format aligned with the PKCS #8 standard.
The parties (you and bunq) exchange their public keys in the first step of the API context creation flow. All the following requests must be signed by both your application and the server. Pass your signature in the X-Bunq-Client-Signature header, and the server will return its signature in the X-Bunq-Server-Signature header.

## Checklist

- Mix task to generate certificates
- Use SSL certificate pinning and hostname verification
- Handle session logout (automatic after 30 mins)


**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `bunq` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bunq, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/bunq](https://hexdocs.pm/bunq).

