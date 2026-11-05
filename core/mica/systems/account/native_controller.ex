defmodule Systems.Account.NativeController do
  @moduledoc "Authenticated account data and profile actions for native clients sharing the web session."
  use MicaWeb, {:controller, [formats: [:json]]}

  alias Frameworks.Concept.LiveContext
  alias Systems.Account

  plug(:private_response)
  plug(:authenticated)

  def show(conn, _params), do: json(conn, account(conn.assigns.current_user))

  def update(conn, %{"profile" => attrs}) when is_map(attrs) do
    user = conn.assigns.current_user
    fields = if user.creator, do: ~w(fullname displayname title), else: ~w(fullname displayname)
    entity = Account.UserProfileEditModel.create(user, Account.Public.get_profile(user))

    changeset =
      Account.UserProfileEditModel.changeset(entity, :auto_save, Map.take(attrs, fields))

    if changeset.valid? do
      case Mica.Persister.save(entity, changeset) do
        {:ok, _} -> json(conn, account(Account.Public.get_user!(user.id)))
        {:error, changeset} -> invalid(conn, changeset)
      end
    else
      invalid(conn, changeset)
    end
  end

  def update(conn, _params),
    do: conn |> put_status(:unprocessable_entity) |> json(%{error: "Invalid profile data"})

  def sign_out(conn, _params) do
    conn |> Account.UserAuth.sign_out_current_user() |> json(%{signed_out: true})
  end

  @max_photo_bytes 2_000_000

  def photo(conn, %{"data" => encoded}) when is_binary(encoded) do
    with true <- byte_size(encoded) <= div(@max_photo_bytes + 2, 3) * 4,
         {:ok, bytes} <- Base.decode64(encoded),
         true <- byte_size(bytes) <= @max_photo_bytes,
         extension when extension in ["jpg", "png"] <- image_extension(bytes) do
      store_photo(conn, bytes, extension)
    else
      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Choose a JPEG or PNG photo under 2 MB"})
    end
  end

  def photo(conn, _params),
    do:
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: "Choose a JPEG or PNG photo under 2 MB"})

  defp image_extension(<<255, 216, 255, _::binary>>), do: "jpg"
  defp image_extension(<<137, 80, 78, 71, 13, 10, 26, 10, _::binary>>), do: "png"
  defp image_extension(_), do: nil

  defp store_photo(conn, bytes, extension) do
    temporary =
      Path.join(System.tmp_dir!(), "native-profile-#{Ecto.UUID.generate()}.#{extension}")

    user = conn.assigns.current_user

    try do
      File.write!(temporary, bytes)

      case Systems.Content.Public.store(temporary, "profile.#{extension}") do
        {:error, _} ->
          conn
          |> put_status(:service_unavailable)
          |> json(%{error: "Could not upload your photo. Please try again."})

        path when is_binary(path) ->
          entity = Account.UserProfileEditModel.create(user, Account.Public.get_profile(user))

          changeset =
            Account.UserProfileEditModel.changeset(entity, :auto_save, %{
              photo_url: Systems.Content.Public.get_public_url(path)
            })

          case Mica.Persister.save(entity, changeset) do
            {:ok, _} -> json(conn, account(Account.Public.get_user!(user.id)))
            {:error, changeset} -> invalid(conn, changeset)
          end
      end
    after
      File.rm(temporary)
    end
  end

  defp account(user) do
    profile = Account.Public.get_profile(user)
    context = LiveContext.new(%{user_id: user.id})

    tabs =
      for tab <- Mica.SaaS.account_tabs(), tab.visible?(user) do
        %{title: title} = tab.build(user, context)
        key = to_string(tab.key())

        %{
          id: key,
          title: title,
          native: key == "profile",
          path: "/user/account?" <> URI.encode_query(%{tab: key, navigation: "external"})
        }
      end

    %{
      profile: %{
        fullname: profile.fullname,
        displayname: user.displayname,
        title: profile.title,
        photo_url: profile.photo_url,
        email: user.email,
        creator: user.creator == true
      },
      tabs: tabs,
      csrf_token: Plug.CSRFProtection.get_csrf_token()
    }
  end

  defp invalid(conn, changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, &Frameworks.Pixel.ErrorHelpers.translate_error/1)

    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Check your profile details", errors: errors})
  end

  defp authenticated(%{assigns: %{current_user: %Account.User{}}} = conn, _opts), do: conn

  defp authenticated(conn, _opts),
    do: conn |> put_status(:unauthorized) |> json(%{error: "Not authenticated"}) |> halt()

  defp private_response(conn, _opts), do: put_resp_header(conn, "cache-control", "no-store")
end
