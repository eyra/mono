# `Mica.ExAws.Hackney`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica/ex_aws/hackney.ex#L1)

The `ExAws.Request.HttpClient` for hackney 4.

ex_aws 2.7.0's own `ExAws.Request.Hackney` has no clause for the
`{:ok, status, headers}` that hackney 4 returns for a HEAD request, so every
`ExAws.S3.head_object/2` raises, and with it `ExAws.S3.download_file/4`.
This client handles that reply as ex_aws 2.6 did. It reads the same options:

    config :ex_aws, :hackney_opts, recv_timeout: 30_000

---

*Consult [api-reference.md](api-reference.md) for complete listing*
