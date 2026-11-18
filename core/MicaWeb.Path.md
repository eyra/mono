# `MicaWeb.Path`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/path.ex#L1)

Mica's paths: `~m`, "m for Mica path".

Mica has no router, so it can't use Phoenix's verified `~p`. `~m` builds a
path exactly the way `~p` does and records it in the module that uses it:

    use MicaWeb.Path

    ~m"/assignment/#{assignment}"           # "/assignment/42", through Phoenix.Param
    ~m"/project?#{[tab: "items", page: 2]}" # "/project?tab=items&page=2"
    ~m"/search?q=#{query}"                  # "/search?q=%C3%A9%26"
    ~m"/images/icons/#{"#{icon}.svg"}"      # a static path, through the endpoint
    url(socket, ~m"/user/reset-password/#{token}")

Every SaaS checks the recorded paths against its own router, with
`MicaWeb.PathCheck`. Paths under the static folders (`statics/0`) go through
the endpoint's `static_path/1` and are not recorded, as with `~p`.

Mica's web module imports `~m` (`use MicaWeb, :verified_routes` and the blocks
that include it). SaaS code keeps Phoenix's `~p`, verified against its own
router.

# `sigil_m`
*macro* 

Builds the path, like `~p`, and records it for `MicaWeb.PathCheck`.

Interpolated segments are encoded with `Phoenix.Param`, an interpolated query
(`?#{params}`) takes a keyword list or map, and a query value (`?q=#{v}`) is
form-encoded.

# `statics`

The top-level folders whose paths are static files.

# `url`
*macro* 

The full URL of a `~m` path, for the endpoint of a conn or socket, like Phoenix's `url/2`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
