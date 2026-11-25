# `MicaWeb.Endpoint`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/endpoint.ex#L1)

Builds the endpoint of a SaaS. Each SaaS has its own:

    defmodule NextWeb.Endpoint do
      use MicaWeb.Endpoint, otp_app: :mica, router: NextWeb.Router
    end

Every SaaS gets the same endpoint: the user and LiveView sockets, the WWW
redirect, the Content and Feldspar plugs, the static files of `otp_app`, the
parsers with the Payment body reader and the session, and `router:` as the
last plug. Its config is the SaaS's: `config :mica, NextWeb.Endpoint, ...`.

Mica reaches the endpoint of the running SaaS through `Mica.SaaS.endpoint/0`.

# `session_options`

The session options of every SaaS endpoint. The session is stored in the
cookie and signed: its contents can be read but not tampered with.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
