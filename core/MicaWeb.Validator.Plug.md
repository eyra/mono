# `MicaWeb.Validator.Plug`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/validator/plug.ex#L1)

A plug to validate input path/query params on your routers.

Usage:

    plug MicaWeb.Validator.Plug, on_error: &MyApp.Validators.on_error_fn/2

Example route registration:

    scope "/a", Systems.Affiliate do
      pipe_through([:browser, :validator])

      get("/:sqid", Controller, :create,
        private: %{
          validate: %{
            sqid: &Systems.Validators.String.valid_non_empty?/1
          },
          validation_handler:
            &Systems.Affiliate.Controller.validation_error_callback/2
        }
      )
    end

# `call`

Validates the parameters from the connection.

If validations (provided via the route's private map) fail,
it calls the provided `on_error` callback with the connection and errors.

# `init`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
