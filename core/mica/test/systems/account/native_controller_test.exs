defmodule Systems.Account.NativeControllerTest do
  use MicaWeb.ConnCase, async: false
  import Phoenix.LiveViewTest
  import Frameworks.Signal.TestHelper
  alias Systems.Account
  alias Mica.Repo

  setup ctx do
    isolate_signals()
    login_as_member(ctx)
  end

  test "signed-out callers cannot read account data" do
    assert %{"error" => "Not authenticated"} =
             MicaWeb.ConnCase.build_conn()
             |> get("/user/account/native/profile")
             |> json_response(401)
  end

  test "returns only the signed-in account and its visible tab destinations", ctx do
    other = Factories.insert!(:member, %{email: "other-native@example.org"})
    response = get(ctx.conn, "/user/account/native/profile?user_id=#{other.id}")
    body = json_response(response, 200)
    assert body["profile"]["email"] == ctx.user.email
    refute inspect(body) =~ other.email
    assert is_binary(body["csrf_token"])
    assert ["no-store"] = get_resp_header(response, "cache-control")

    assert Enum.map(body["tabs"], & &1["id"]) ==
             Enum.map(Account.PageBuilder.tab_keys(ctx.user), &to_string/1)

    assert %{"native" => true} = Enum.find(body["tabs"], &(&1["id"] == "profile"))
    assert Enum.all?(body["tabs"], &String.starts_with?(&1["path"], "/user/account?"))
  end

  test "saves through existing profile rules and cannot change identity or role", ctx do
    other = Factories.insert!(:member)
    {conn, token} = ready(ctx.conn)

    response =
      mutate(conn, token, :post, "/user/account/native/profile", %{
        profile: %{
          fullname: "Native Name",
          displayname: "Native",
          user_id: other.id,
          creator: true,
          email: "changed@example.org",
          photo_url: "https://other/photo"
        }
      })

    assert %{"profile" => %{"fullname" => "Native Name", "displayname" => "Native"}} =
             json_response(response, 200)

    assert Account.Public.get_profile(ctx.user).fullname == "Native Name"
    assert Account.Public.get_profile(other).fullname != "Native Name"
    user = Repo.reload!(ctx.user)
    assert user.email == ctx.user.email
    assert user.creator == ctx.user.creator
    refute Account.Public.get_profile(user).photo_url == "https://other/photo"
  end

  test "invalid field types return validation errors without changing the profile", ctx do
    {conn, token} = ready(ctx.conn)

    assert %{"errors" => %{"fullname" => [_ | _]}} =
             mutate(conn, token, :post, "/user/account/native/profile", %{
               profile: %{fullname: %{bad: "type"}}
             })
             |> json_response(422)
  end

  test "mutation requires the CSRF token, even with a valid session", ctx do
    {conn, _token} = ready(put_private(ctx.conn, :plug_skip_csrf_protection, false))

    assert_raise Plug.CSRFProtection.InvalidCSRFTokenError, fn ->
      conn
      |> recycle()
      |> put_private(:plug_skip_csrf_protection, false)
      |> post("/user/account/native/profile", %{profile: %{displayname: "Forged"}})
    end
  end

  test "sign out revokes the shared session and returns JSON", ctx do
    old_token = get_session(ctx.conn, :user_token)
    {conn, token} = ready(ctx.conn)
    response = mutate(conn, token, :delete, "/user/account/native/session", %{})
    assert %{"signed_out" => true} = json_response(response, 200)
    assert Account.Public.get_user_by_session_token(old_token) == nil
    assert response |> recycle() |> get("/user/account/native/profile") |> json_response(401)
  end

  test "photo upload uses content storage and changes only the authenticated profile", ctx do
    {conn, token} = ready(ctx.conn)

    png =
      Base.decode64!(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jXioAAAAASUVORK5CYII="
      )

    response =
      mutate(conn, token, :post, "/user/account/native/photo", %{data: Base.encode64(png)})

    assert %{"profile" => %{"photo_url" => url}} = json_response(response, 200)
    assert url == Account.Public.get_profile(ctx.user).photo_url
    assert Systems.Content.Public.stored_url?(url)
    path = Systems.Content.Public.get_local_path(url)
    assert File.read!(path) == png
    File.rm!(path)
  end

  test "photo upload rejects non-raster data and oversized content", ctx do
    {conn, token} = ready(ctx.conn)

    for data <- [Base.encode64("<svg onload='x()'></svg>"), String.duplicate("A", 2_666_672)] do
      assert mutate(conn, token, :post, "/user/account/native/photo", %{data: data})
             |> json_response(422)
    end
  end

  test "external navigation renders just the selected visible Account tab", ctx do
    pool =
      Systems.Pool.Public.get_panl() ||
        Factories.insert!(:pool, %{name: "Panl", director: :citizen})

    Systems.Pool.Public.add_participant!(pool, ctx.user)
    {:ok, view, _} = live(ctx.conn, "/user/account?tab=features&navigation=external")
    assert has_element?(view, "[data-testid=features-view]")
    refute has_element?(view, "[data-testid=profile-view]")
  end

  test "an unknown tab cannot crash Account", ctx do
    {:ok, view, _} = live(ctx.conn, "/user/account?tab=not_a_real_native_tab&navigation=external")
    assert has_element?(view, "[data-testid=profile-view]")
  end

  defp ready(conn) do
    response = get(conn, "/user/account/native/profile")
    {response, json_response(response, 200)["csrf_token"]}
  end

  defp mutate(conn, token, method, path, body) do
    conn = conn |> recycle() |> put_req_header("x-csrf-token", token)

    case method do
      :post -> post(conn, path, body)
      :delete -> delete(conn, path, body)
    end
  end
end
