# `MicaWeb.PathCheck`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/path_check.ex#L1)

Checks Mica's paths (`~m`, `MicaWeb.Path`) against a SaaS's router.

Mica has no router, so its paths can't be verified when Mica compiles. Each
SaaS checks them against its own router instead, in two ways:

  * at compile time: `use MicaWeb.PathCheck` in the router prints a warning for
    every Mica path that fails, with the file and line of the `~m`
  * as a test that fails: `MicaWeb.PathCheck.unmatched(router) == []`

A path passes when the router has a route for it and that route is served by
a Mica module (a LiveView or a plug in `Mica`, `MicaWeb`, `Systems` or
`Frameworks`). A route the SaaS put in its override routes passes too: those
are its own pages that shadow Mica's, such as its sign-in pages. The router
records them with `overrides/1`.

    warning: Mica path ~m"/assignment/#{id}/landng" matches no route in NextWeb.Router
    warning: Mica path ~m"/console" is served by MicaSaas.ConsolePage, not by Mica

The check reads the paths of every module of Mica's application and of the
router's application that uses `~m`, which includes SaaS modules that get a
`~m` through one of Mica's macros. The compile-time warning appears when the
router compiles; the test always checks every path.

# `format`

The issues from `unmatched/2` as text, one per path, with file and line.

# `message`

The warning text of an issue from `unmatched/2`.

# `overrides`
*macro* 

Splices `block`, the SaaS's override routes, into the router and records
their paths, which the check accepts whoever serves them.

# `unmatched`

The Mica paths that fail against `router`: `%{route:, path:, file:, line:,
module:, reason:}`, where `reason` is `:no_route` or `{:served_by, module}`.
`modules` defaults to every module that has Mica paths.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
