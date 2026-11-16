defmodule MicaSaasWeb.Features.FeatureCaseSessionTest do
  @moduledoc """
  A feature starts its Chrome session through
  `MicaSaasWeb.FeatureCase.create_session/2`, which turns a session chromedriver
  refuses into its reason instead of "invalid session id". Wallaby reaches it
  through the deprecated `create_session_fn` option; this fails when a Wallaby
  upgrade drops that option.
  """
  use MicaSaasWeb.FeatureCase

  @tag :feature
  feature "starts its session through MicaSaasWeb.FeatureCase.create_session/2", %{
    session: _session
  } do
    assert Process.get({MicaSaasWeb.FeatureCase, :create_session})
  end
end
