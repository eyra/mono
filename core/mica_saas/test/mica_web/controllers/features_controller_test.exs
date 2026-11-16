defmodule MicaWeb.FeaturesControllerTest do
  use MicaWeb.ConnCase, async: false
  use Mica.FeatureFlags.Test

  test "lists the effective flags that are on, including SaaS defaults", %{conn: conn} do
    Mica.Env.put(:features, otp: false, debug: true)

    expected =
      for {name, true} <- Mica.FeatureFlags.effective(), do: Atom.to_string(name)

    assert %{"features" => ^expected} = conn |> get("/.status/features") |> json_response(200)
    assert "password_sign_in" in expected
    assert "debug" in expected
    refute "otp" in expected
  end
end
