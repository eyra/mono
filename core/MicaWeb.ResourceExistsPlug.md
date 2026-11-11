# `MicaWeb.ResourceExistsPlug`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/resource_exists_plug.ex#L1)

A plug that checks if a resource exists before continuing.

If the resource doesn't exist, redirects to /not_found.
This separates existence checking (404) from authorization (403).

## Usage in router

    pipeline :assignment_exists do
      plug MicaWeb.ResourceExistsPlug, param: "id", fetch: {Assignment.Public, :get}
    end

    scope "/assignment/:id" do
      pipe_through [:browser, :assignment_exists]
      live "/", Assignment.CrewPage
    end

# `call`

# `init`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
