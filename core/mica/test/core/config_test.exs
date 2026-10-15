defmodule Core.ConfigTest do
  @moduledoc """
  `Core.Config.payment_provider/0` runs at boot from `config/runtime*.exs` to
  resolve `:payment_provider` from the `PAYMENT_PROVIDER` env var. It must fail
  loudly on anything it can't resolve: a silent default would route real
  payments through the wrong adapter and exclude them from reconciliation.
  """
  # Mutates the PAYMENT_PROVIDER env var, which is global to the VM.
  use ExUnit.Case, async: false

  setup do
    original = System.get_env("PAYMENT_PROVIDER")

    on_exit(fn ->
      case original do
        nil -> System.delete_env("PAYMENT_PROVIDER")
        value -> System.put_env("PAYMENT_PROVIDER", value)
      end
    end)

    :ok
  end

  describe "payment_provider/0" do
    test "resolves a configured provider name to its adapter module" do
      System.put_env("PAYMENT_PROVIDER", "opp")
      assert Core.Config.payment_provider() == Systems.Payment.Provider.OPP

      System.put_env("PAYMENT_PROVIDER", "local")
      assert Core.Config.payment_provider() == Systems.Payment.Provider.Local
    end

    test "raises when PAYMENT_PROVIDER is not set" do
      System.delete_env("PAYMENT_PROVIDER")

      assert_raise RuntimeError, ~r/PAYMENT_PROVIDER is not set/, fn ->
        Core.Config.payment_provider()
      end
    end

    test "raises when PAYMENT_PROVIDER is set but empty" do
      System.put_env("PAYMENT_PROVIDER", "")

      assert_raise RuntimeError, ~r/PAYMENT_PROVIDER is not set/, fn ->
        Core.Config.payment_provider()
      end
    end

    test "raises on an unknown provider name rather than falling back to a default" do
      System.put_env("PAYMENT_PROVIDER", "stripe")

      assert_raise KeyError, fn -> Core.Config.payment_provider() end
    end
  end
end
