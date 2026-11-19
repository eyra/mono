defmodule MicaSaasWeb.Features.SmokeTest do
  use MicaSaasWeb.FeatureCase

  @tag :feature
  feature "homepage loads", %{session: session} do
    session
    |> visit("/")
    |> assert_has(Query.css("body"))
  end
end
