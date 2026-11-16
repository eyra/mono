defmodule Frameworks.Pixel.LogoTest do
  # The pool assets are the SaaS's config, which Mica reads at runtime: Mica is
  # compiled once for every SaaS (code-compose). Changes the :pixel config.
  use ExUnit.Case, async: false

  alias Frameworks.Pixel.Logo

  setup do
    previous = Mica.Env.get(:pixel)
    on_exit(fn -> Mica.Env.put(:pixel, previous) end)
  end

  test "a pool logo that the config lists after compile time has a path" do
    Mica.Env.put(:pixel, pool_assets: [:logo_test_pool])
    assert Logo.path(:logo_test_pool, :pool) == "/images/logos/pools/logo_test_pool.svg"
  end

  test "a pool logo that the config no longer lists has none" do
    Mica.Env.put(:pixel, pool_assets: [])
    assert Logo.path(:logo_test_pool, :pool) == nil
  end
end
