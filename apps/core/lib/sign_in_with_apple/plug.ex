defmodule SignInWithApple.CallbackPlug do
  import SignInWithApple.Helpers, only: [backend_module: 1, apply_defaults: 1]

  def init(options) when is_list(options), do: options |> apply_defaults()

  def call(conn, config) do
    {:ok, id_token} = Map.fetch(conn.body_params, "id_token")
    {:ok, %{claims: claims}} = backend_module(config).validate_id_token(config, id_token)

    user =
      if user = SignInWithApple.get_user_by_sub(claims["sub"]) do
        user
      else
        {:ok, user_name_params} = conn.body_params["user"] |> Jason.decode!() |> Map.fetch("name")

        {:ok, signed_in_apple_user} =
          SignInWithApple.register_user(%{
            sub: claims["sub"],
            email: claims["email"],
            is_private_email: claims["is_private_email"],
            first_name: user_name_params["firstName"],
            middle_name: user_name_params["middleName"],
            last_name: user_name_params["lastName"]
          })

        signed_in_apple_user.user
      end

    CoreWeb.UserAuth.log_in_user(conn, user)
  end
end
