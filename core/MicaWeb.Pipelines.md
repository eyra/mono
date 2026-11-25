# `MicaWeb.Pipelines`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/pipelines.ex#L1)

The pipelines Mica's routes `pipe_through`, for a SaaS router:

    defmodule NextWeb.Router do
      use NextWeb, :router
      require MicaWeb.Pipelines

      MicaWeb.Pipelines.define()
      ...
    end

Their names are part of the contract between Mica's systems and every SaaS
router: `:browser_base`, `:browser_secure`, `:browser`, `:browser_unprotected`,
`:api` and `:validator`. The router also gets the function plugs routes pipe
through, such as `:require_authenticated_user` (`Systems.Account.UserAuth`).

# `define`
*macro* 

---

*Consult [api-reference.md](api-reference.md) for complete listing*
