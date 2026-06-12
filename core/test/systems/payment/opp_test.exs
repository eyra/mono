defmodule Systems.Payment.Provider.OPPTest do
  @moduledoc """
  Exercises the real OPP provider HTTP layer (parsing of merchant +
  bank-account responses) against a Bypass server. The rest of the suite
  uses ProviderMock, so without this the OPP parsers — including the
  bank-account additions for UC-OPP-06.A1 — would be unreachable by tests.
  """
  use ExUnit.Case, async: false

  alias Systems.Payment.Provider.OPP
  alias Systems.Payment.Error

  setup do
    bypass = Bypass.open()
    previous = Application.get_env(:core, OPP)

    Application.put_env(
      :core,
      OPP,
      Keyword.merge(previous || [],
        base_url: "http://localhost:#{bypass.port}",
        api_key: "test_key",
        notification_secret: "test_secret"
      )
    )

    on_exit(fn -> Application.put_env(:core, OPP, previous) end)

    {:ok, bypass: bypass}
  end

  describe "create_bank_account/2" do
    test "POSTs to the merchant bank_accounts collection and parses the response",
         %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/merchants/m_1/bank_accounts", fn conn ->
        Plug.Conn.resp(
          conn,
          200,
          ~s<{"uid": "ba_1", "status": "new", "verification_url": "https://opp.test/verify/ba_1"}>
        )
      end)

      assert {:ok,
              %{uid: "ba_1", status: "new", verification_url: "https://opp.test/verify/ba_1"}} =
               OPP.create_bank_account("m_1", %{notify_url: "x", return_url: "y"})
    end

    test "defaults status to \"new\" and verification_url to nil when absent",
         %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/merchants/m_1/bank_accounts", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"uid": "ba_2"}>)
      end)

      assert {:ok, %{uid: "ba_2", status: "new", verification_url: nil}} =
               OPP.create_bank_account("m_1", %{})
    end

    test "surfaces an OPP API error on non-2xx", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/merchants/m_1/bank_accounts", fn conn ->
        Plug.Conn.resp(conn, 422, ~s<{"error": "nope"}>)
      end)

      assert {:error, %Systems.Payment.Error{code: :api_error}} =
               OPP.create_bank_account("m_1", %{})
    end
  end

  describe "list_bank_accounts/1" do
    test "maps a multi-entry data array", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/merchants/m_1/bank_accounts", fn conn ->
        Plug.Conn.resp(
          conn,
          200,
          ~s<{"data": [{"uid": "ba_a", "status": "approved"}, {"uid": "ba_b", "status": "disapproved"}]}>
        )
      end)

      assert {:ok,
              [
                %{uid: "ba_a", status: "approved"},
                %{uid: "ba_b", status: "disapproved"}
              ]} = OPP.list_bank_accounts("m_1")
    end

    test "returns an empty list for an empty data array", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/merchants/m_1/bank_accounts", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"data": []}>)
      end)

      assert {:ok, []} = OPP.list_bank_accounts("m_1")
    end
  end

  describe "bank-account guards" do
    test "create_bank_account/2 crashes on a non-binary merchant_uid" do
      assert_raise FunctionClauseError, fn -> OPP.create_bank_account(nil, %{}) end
    end

    test "create_bank_account/2 crashes on non-map attrs" do
      assert_raise FunctionClauseError, fn -> OPP.create_bank_account("m_1", "nope") end
    end

    test "list_bank_accounts/1 crashes on a non-binary merchant_uid" do
      assert_raise FunctionClauseError, fn -> OPP.list_bank_accounts(nil) end
    end
  end

  describe "create_merchant/1 compliance parsing" do
    test "maps nested compliance status, level and overview_url", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/merchants", fn conn ->
        Plug.Conn.resp(
          conn,
          200,
          ~s<{"uid": "m_9", "status": "pending", "compliance": {"status": "unverified", "level": 100, "overview_url": "https://opp.test/overview/m_9"}}>
        )
      end)

      assert {:ok,
              %{
                uid: "m_9",
                status: "pending",
                kyc_level: 100,
                compliance_status: "unverified",
                overview_url: "https://opp.test/overview/m_9"
              }} = OPP.create_merchant(%{emailaddress: "a@b.c"})
    end

    test "defaults compliance fields when the compliance key is absent",
         %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/merchants", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"uid": "m_10", "status": "new"}>)
      end)

      assert {:ok,
              %{
                uid: "m_10",
                status: "new",
                kyc_level: 0,
                compliance_status: "unverified",
                overview_url: nil
              }} = OPP.create_merchant(%{emailaddress: "a@b.c"})
    end
  end

  describe "create_withdrawal/4" do
    test "maps the currency, sends the idempotency key + reference, and parses the response",
         %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/merchants/m_1/withdrawals", fn conn ->
        assert ["payout=7"] = Plug.Conn.get_req_header(conn, "idempotency-key")
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        body = Jason.decode!(raw)
        assert body["currency"] == "EUR"
        assert body["reference"] == "payout=7"
        assert body["amount"] == 1000
        # OPP rejects withdrawals missing these (HTTP 400), so they must be sent.
        assert is_binary(body["description"]) and body["description"] != ""
        assert body["notify_url"] =~ "/api/payment/webhook/"

        Plug.Conn.resp(conn, 200, ~s<{"uid": "w_1", "status": "pending", "amount": 1000}>)
      end)

      assert {:ok, %{uid: "w_1", status: "pending", amount: 1000}} =
               OPP.create_withdrawal("m_1", :EUR, %{amount: 1000}, "payout=7")
    end

    # Regression for the UC-OPP-06 payout crash: an unknown currency must
    # return an error tuple (not raise) so the caller reverts the payout lock
    # instead of crashing after the funds were already locked. No HTTP request
    # is made — the Bypass server has no expectation, so a POST would fail.
    test "returns an error for an unsupported currency without calling OPP" do
      assert {:error, %Error{code: :unsupported_currency}} =
               OPP.create_withdrawal("m_1", :eur, %{amount: 1000}, "payout=7")
    end
  end

  describe "create_charge/4" do
    test "POSTs a balance charge from->to with idempotency key and parses the response",
         %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/charges", fn conn ->
        assert ["payout=7,type=charge"] = Plug.Conn.get_req_header(conn, "idempotency-key")
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        body = Jason.decode!(raw)
        assert body["type"] == "balance"
        assert body["currency"] == "EUR"
        assert body["from_owner_uid"] == "mer_platform"
        assert body["to_owner_uid"] == "mer_participant"
        assert body["amount"] == 1000

        Plug.Conn.resp(conn, 200, ~s<{"uid": "chg_1", "status": "created", "amount": 1000}>)
      end)

      assert {:ok, %{uid: "chg_1", status: "created", amount: 1000}} =
               OPP.create_charge("mer_platform", "mer_participant", 1000, "payout=7,type=charge")
    end

    test "surfaces an OPP API error on non-2xx", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/charges", fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"error": {"message": "nope"}}>)
      end)

      assert {:error, %Error{code: :api_error}} =
               OPP.create_charge("mer_platform", "mer_participant", 1000, "payout=7,type=charge")
    end
  end
end
