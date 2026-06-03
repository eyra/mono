defmodule Systems.Payment.PublicTest do
  use Core.DataCase
  import Mox

  alias Core.Factories
  alias Systems.Account
  alias Systems.Payment
  alias Systems.Payment.ProviderMock

  setup :verify_on_exit!

  defp fresh_user(overrides) do
    Factories.insert!(:member, Map.merge(%{creator: false}, overrides))
  end

  defp merchant(overrides) do
    Map.merge(
      %{
        uid: "m_test_#{System.unique_integer([:positive])}",
        status: "live",
        kyc_level: 100,
        compliance_status: "verified",
        overview_url: nil
      },
      overrides
    )
  end

  describe "ensure_merchant_for/1 — user already has a merchant_uid" do
    test "skips create_merchant and returns the fresh merchant payload from get_merchant" do
      user = fresh_user(%{merchant_uid: "m_existing"})

      expect(ProviderMock, :get_merchant, fn "m_existing" ->
        {:ok, merchant(%{uid: "m_existing", overview_url: "https://opp.test/overview/existing"})}
      end)

      assert {:ok, {%Account.User{merchant_uid: "m_existing"} = same_user, m}} =
               Payment.Public.ensure_merchant_for(user)

      assert same_user.id == user.id
      assert m.uid == "m_existing"
      assert m.overview_url == "https://opp.test/overview/existing"
    end

    test "bubbles up an OPP error from get_merchant" do
      user = fresh_user(%{merchant_uid: "m_unreachable"})

      expect(ProviderMock, :get_merchant, fn "m_unreachable" ->
        {:error, %Systems.Payment.Error{code: :http_error, message: "boom"}}
      end)

      assert {:error, %Systems.Payment.Error{code: :http_error}} =
               Payment.Public.ensure_merchant_for(user)
    end
  end

  describe "ensure_merchant_for/1 — user has no merchant_uid" do
    test "creates a merchant at OPP and persists the new uid on the user" do
      user = fresh_user(%{merchant_uid: nil})

      expect(ProviderMock, :create_merchant, fn %{emailaddress: email} ->
        assert email == user.email
        {:ok, merchant(%{uid: "m_freshly_created"})}
      end)

      assert {:ok,
              {%Account.User{merchant_uid: "m_freshly_created"}, %{uid: "m_freshly_created"}}} =
               Payment.Public.ensure_merchant_for(user)

      # Persisted on the user row, not just returned in memory.
      assert %{merchant_uid: "m_freshly_created"} = Core.Repo.reload!(user)
    end

    test "falls back to find_merchant_by_email on OPP email-collision error" do
      user = fresh_user(%{merchant_uid: nil})

      ProviderMock
      |> expect(:create_merchant, fn _ ->
        {:error,
         %Systems.Payment.Error{
           code: :validation,
           message: "email taken",
           details: %{body: %{"error" => %{"parameters" => %{"emailaddress" => ["taken"]}}}}
         }}
      end)
      |> expect(:find_merchant_by_email, fn email ->
        assert email == user.email
        {:ok, merchant(%{uid: "m_recovered"})}
      end)

      assert {:ok, {%Account.User{merchant_uid: "m_recovered"}, %{uid: "m_recovered"}}} =
               Payment.Public.ensure_merchant_for(user)

      assert %{merchant_uid: "m_recovered"} = Core.Repo.reload!(user)
    end

    test "bubbles up a non-collision create_merchant error without persisting anything" do
      user = fresh_user(%{merchant_uid: nil})

      expect(ProviderMock, :create_merchant, fn _ ->
        {:error, %Systems.Payment.Error{code: :http_error, message: "down"}}
      end)

      assert {:error, %Systems.Payment.Error{code: :http_error}} =
               Payment.Public.ensure_merchant_for(user)

      assert %{merchant_uid: nil} = Core.Repo.reload!(user)
    end
  end

  describe "ensure_bank_account_for/1" do
    test "returns the existing bank account when one already exists (no create call)" do
      existing = %{uid: "ba_existing", status: "approved", verification_url: nil}
      expect(ProviderMock, :list_bank_accounts, fn "m_x" -> {:ok, [existing]} end)
      # No :create_bank_account expectation -> Mox fails if invoked.

      assert {:ok, ^existing} = Payment.Public.ensure_bank_account_for("m_x")
    end

    test "creates a bank account when the merchant has none" do
      ProviderMock
      |> expect(:list_bank_accounts, fn "m_y" -> {:ok, []} end)
      |> expect(:create_bank_account, fn "m_y", attrs ->
        # OPP needs both notify_url + return_url to complete the
        # verification round-trip back to Next.
        assert is_binary(attrs.notify_url)
        assert is_binary(attrs.return_url)
        assert attrs.is_default == true

        {:ok, %{uid: "ba_new", status: "new", verification_url: "https://opp.test/ba/verify"}}
      end)

      assert {:ok, %{uid: "ba_new", status: "new"}} =
               Payment.Public.ensure_bank_account_for("m_y")
    end

    test "bubbles up list_bank_accounts errors without calling create_bank_account" do
      expect(ProviderMock, :list_bank_accounts, fn "m_z" ->
        {:error, %Systems.Payment.Error{code: :http_error, message: "down"}}
      end)

      assert {:error, %Systems.Payment.Error{code: :http_error}} =
               Payment.Public.ensure_bank_account_for("m_z")
    end

    test "reuses a usable (non-disapproved) account even when a disapproved one exists" do
      accounts = [
        %{uid: "ba_bad", status: "disapproved", verification_url: nil},
        %{uid: "ba_good", status: "new", verification_url: "https://opp.test/v"}
      ]

      expect(ProviderMock, :list_bank_accounts, fn "m_mix" -> {:ok, accounts} end)
      # No :create_bank_account expectation -> Mox fails if a new one is created.

      assert {:ok, %{uid: "ba_good"}} = Payment.Public.ensure_bank_account_for("m_mix")
    end

    test "creates a fresh account when the only existing one is disapproved" do
      ProviderMock
      |> expect(:list_bank_accounts, fn "m_dis" ->
        {:ok, [%{uid: "ba_bad", status: "disapproved", verification_url: nil}]}
      end)
      |> expect(:create_bank_account, fn "m_dis", _attrs ->
        {:ok, %{uid: "ba_fresh", status: "new", verification_url: "https://opp.test/v2"}}
      end)

      assert {:ok, %{uid: "ba_fresh"}} = Payment.Public.ensure_bank_account_for("m_dis")
    end
  end
end
