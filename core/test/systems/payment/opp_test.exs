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
              %{
                uid: "ba_1",
                status: :new,
                raw_status: "new",
                verification_url: "https://opp.test/verify/ba_1"
              }} =
               OPP.create_bank_account("m_1", %{notify_url: "x", return_url: "y"})
    end

    test "defaults status to \"new\" and verification_url to nil when absent",
         %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/merchants/m_1/bank_accounts", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"uid": "ba_2"}>)
      end)

      assert {:ok, %{uid: "ba_2", status: :new, raw_status: "new", verification_url: nil}} =
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
                %{uid: "ba_a", status: :verified, raw_status: "approved"},
                %{uid: "ba_b", status: :rejected, raw_status: "disapproved"}
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

  describe "add_merchant_phone/2" do
    test "fetches the primary contact, posts the phone, returns the refreshed merchant",
         %{bypass: bypass} do
      # Called twice: once to read the contact uid, once to re-fetch the merchant.
      Bypass.expect(bypass, "GET", "/merchants/m_1", fn conn ->
        Plug.Conn.resp(
          conn,
          200,
          ~s<{"uid": "m_1", "contacts": {"data": [{"uid": "c_1"}]}, "compliance": {"level": 200, "status": "verified"}}>
        )
      end)

      Bypass.expect_once(bypass, "POST", "/merchants/m_1/contacts/c_1", fn conn ->
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        body = Jason.decode!(raw)
        assert [%{"phonenumber" => "+31612345678"}] = body["phonenumbers"]
        Plug.Conn.resp(conn, 200, ~s<{"uid": "c_1"}>)
      end)

      assert {:ok, %{uid: "m_1", compliance_status: "verified", kyc_level: 200}} =
               OPP.add_merchant_phone("m_1", "+31612345678")
    end

    test "returns a not_found error when the merchant has no contact", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/merchants/m_1", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"uid": "m_1"}>)
      end)

      assert {:error, %Error{code: :not_found}} = OPP.add_merchant_phone("m_1", "+31612345678")
    end

    test "accepts a bare-list contacts shape (no data wrapper)", %{bypass: bypass} do
      # OPP has been observed returning both shapes; the code handles either.
      # Pin the bare-list variant so a future refactor can't silently drop it.
      Bypass.expect(bypass, "GET", "/merchants/m_1", fn conn ->
        Plug.Conn.resp(
          conn,
          200,
          ~s<{"uid": "m_1", "contacts": [{"uid": "c_1"}], "compliance": {"level": 200, "status": "verified"}}>
        )
      end)

      Bypass.expect_once(bypass, "POST", "/merchants/m_1/contacts/c_1", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"uid": "c_1"}>)
      end)

      assert {:ok, %{uid: "m_1", compliance_status: "verified", kyc_level: 200}} =
               OPP.add_merchant_phone("m_1", "+31612345678")
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

      assert {:ok, %{uid: "w_1", status: :pending, raw_status: "pending", amount: 1000}} =
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

  # The adapter owns the vocabulary: OPP's status strings are normalized here so
  # that no domain code ever matches on them. `raw_status` keeps OPP's own word
  # for the audit trail.
  # How a stranded withdrawal is found again: its uid was never recorded, so the
  # only handle left is the `reference` we set when creating it.
  describe "list_withdrawals/1" do
    test "lists a merchant's withdrawals with their reference", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/merchants/m_1/withdrawals", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"data": [
          {"uid": "w_1", "status": "completed", "reference": "payout=abc,type=withdrawal,attempt=0", "amount": 1000},
          {"uid": "w_2", "status": "failed", "reference": "payout=def,type=withdrawal,attempt=0", "amount": 500}
        ]}>)
      end)

      assert {:ok, [first, second]} = OPP.list_withdrawals("m_1")

      assert %{
               uid: "w_1",
               status: :completed,
               reference: "payout=abc,type=withdrawal,attempt=0",
               amount: 1000
             } = first

      assert %{uid: "w_2", status: :failed, reference: "payout=def,type=withdrawal,attempt=0"} =
               second
    end

    test "a merchant with no withdrawals returns an empty list, not an error", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/merchants/m_1/withdrawals", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"data": []}>)
      end)

      assert {:ok, []} = OPP.list_withdrawals("m_1")
    end

    test "surfaces an OPP API error on non-2xx", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/merchants/m_1/withdrawals", fn conn ->
        Plug.Conn.resp(conn, 500, ~s<{"error": {"message": "boom"}}>)
      end)

      assert {:error, %Error{code: :api_error}} = OPP.list_withdrawals("m_1")
    end
  end

  describe "get_withdrawal/1 status normalization" do
    defp stub_withdrawal_status(bypass, opp_status) do
      Bypass.expect_once(bypass, "GET", "/withdrawals/w_1", fn conn ->
        Plug.Conn.resp(conn, 200, ~s<{"uid": "w_1", "status": "#{opp_status}", "amount": 1000}>)
      end)
    end

    test ~s(normalizes "completed" to :completed), %{bypass: bypass} do
      stub_withdrawal_status(bypass, "completed")

      assert {:ok, %{status: :completed, raw_status: "completed"}} = OPP.get_withdrawal("w_1")
    end

    test ~s(normalizes "failed" to :failed), %{bypass: bypass} do
      stub_withdrawal_status(bypass, "failed")

      assert {:ok, %{status: :failed, raw_status: "failed"}} = OPP.get_withdrawal("w_1")
    end

    test ~s(normalizes "disapproved" to :failed, keeping the raw word), %{bypass: bypass} do
      stub_withdrawal_status(bypass, "disapproved")

      assert {:ok, %{status: :failed, raw_status: "disapproved"}} = OPP.get_withdrawal("w_1")
    end

    test ~s(normalizes "pending" to :pending), %{bypass: bypass} do
      stub_withdrawal_status(bypass, "pending")

      assert {:ok, %{status: :pending, raw_status: "pending"}} = OPP.get_withdrawal("w_1")
    end

    # The safety property: a status OPP adds later must never finalize or fail a
    # payout, so anything unrecognised is :pending.
    test "normalizes an unrecognised status to :pending", %{bypass: bypass} do
      stub_withdrawal_status(bypass, "some_future_status")

      assert {:ok, %{status: :pending, raw_status: "some_future_status"}} =
               OPP.get_withdrawal("w_1")
    end
  end

  describe "get_transaction/1 status normalization" do
    defp stub_transaction_status(bypass, opp_status) do
      Bypass.expect_once(bypass, "GET", "/transactions/t_1", fn conn ->
        Plug.Conn.resp(
          conn,
          200,
          ~s<{"uid": "t_1", "status": "#{opp_status}", "total_amount": 1000}>
        )
      end)
    end

    test ~s(normalizes "completed" to :completed), %{bypass: bypass} do
      stub_transaction_status(bypass, "completed")

      assert {:ok, %{status: :completed, raw_status: "completed"}} = OPP.get_transaction("t_1")
    end

    test ~s(normalizes "failed" to :failed), %{bypass: bypass} do
      stub_transaction_status(bypass, "failed")

      assert {:ok, %{status: :failed, raw_status: "failed"}} = OPP.get_transaction("t_1")
    end

    # OPP documents "cancelled" as terminal — "A new transaction needs to be
    # created" — so a declined pay-in must not linger as :pending and keep
    # offering the retry CTA on the same transaction.
    test ~s(normalizes "cancelled" to :failed, keeping the raw word), %{bypass: bypass} do
      stub_transaction_status(bypass, "cancelled")

      assert {:ok, %{status: :failed, raw_status: "cancelled"}} = OPP.get_transaction("t_1")
    end

    test ~s(normalizes "expired" to :failed, keeping the raw word), %{bypass: bypass} do
      stub_transaction_status(bypass, "expired")

      assert {:ok, %{status: :failed, raw_status: "expired"}} = OPP.get_transaction("t_1")
    end

    test ~s(normalizes "pending" to :pending), %{bypass: bypass} do
      stub_transaction_status(bypass, "pending")

      assert {:ok, %{status: :pending, raw_status: "pending"}} = OPP.get_transaction("t_1")
    end

    # "planned" means the issuer reserved the money but OPP has not claimed it
    # yet — still in flight, so not terminal.
    test ~s(normalizes "planned" to :pending), %{bypass: bypass} do
      stub_transaction_status(bypass, "planned")

      assert {:ok, %{status: :pending, raw_status: "planned"}} = OPP.get_transaction("t_1")
    end

    # The safety property: a status OPP adds later must never finalize or fail a
    # pay-in, so anything unrecognised is :pending.
    test "normalizes an unrecognised status to :pending", %{bypass: bypass} do
      stub_transaction_status(bypass, "some_future_status")

      assert {:ok, %{status: :pending, raw_status: "some_future_status"}} =
               OPP.get_transaction("t_1")
    end
  end

  describe "transfer_to_merchant/4" do
    test "POSTs a balance charge from->to with idempotency key and parses the response",
         %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/charges", fn conn ->
        assert ["payout=7,type=transfer"] = Plug.Conn.get_req_header(conn, "idempotency-key")
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        body = Jason.decode!(raw)
        assert body["type"] == "balance"
        assert body["currency"] == "EUR"
        assert body["from_owner_uid"] == "mer_platform"
        assert body["to_owner_uid"] == "mer_participant"
        assert body["amount"] == 1000

        # A charge has no `reference` field and cannot be listed, so metadata is
        # the only thing tying it back to its payout for a manual investigation.
        assert body["metadata"]["reference"] == "payout=7,type=transfer"

        Plug.Conn.resp(conn, 200, ~s<{"uid": "chg_1", "status": "created", "amount": 1000}>)
      end)

      assert {:ok, %{uid: "chg_1", status: :pending, raw_status: "created", amount: 1000}} =
               OPP.transfer_to_merchant(
                 "mer_platform",
                 "mer_participant",
                 1000,
                 "payout=7,type=transfer"
               )
    end

    test "surfaces an OPP API error on non-2xx", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/charges", fn conn ->
        Plug.Conn.resp(conn, 400, ~s<{"error": {"message": "nope"}}>)
      end)

      assert {:error, %Error{code: :api_error}} =
               OPP.transfer_to_merchant(
                 "mer_platform",
                 "mer_participant",
                 1000,
                 "payout=7,type=transfer"
               )
    end
  end

  # OPP's `date` filter on /withdrawals is silently ignored and /charges has no
  # date filter at all, so the creation cutoff is enforced client-side. These
  # cover that windowing, since a server that ignores the filter cannot.
  describe "list_recent_withdrawals/1" do
    defp unix(iso), do: iso |> DateTime.from_iso8601() |> elem(1) |> DateTime.to_unix()

    defp withdrawal_json(uid, reference, created) do
      ~s<{"uid": "#{uid}", "object": "withdrawal", "status": "completed", > <>
        ~s<"reference": "#{reference}", "amount": 1000, "created": #{created}}>
    end

    defp page_json(items, last_page) do
      ~s<{"object": "list", "last_page": #{last_page}, "data": [#{Enum.join(items, ",")}]}>
    end

    test "parses reference and created into the withdrawal", %{bypass: bypass} do
      created = unix("2026-07-20T12:00:00Z")

      Bypass.expect_once(bypass, "GET", "/withdrawals", fn conn ->
        Plug.Conn.resp(
          conn,
          200,
          page_json(
            [withdrawal_json("wtd_1", "payout=abc,type=withdrawal,attempt=0", created)],
            1
          )
        )
      end)

      assert {:ok, [withdrawal]} = OPP.list_recent_withdrawals(~U[2026-07-01 00:00:00Z])

      assert %{
               uid: "wtd_1",
               status: :completed,
               reference: "payout=abc,type=withdrawal,attempt=0",
               amount: 1000
             } = withdrawal

      assert DateTime.to_unix(withdrawal.created) == created
    end

    test "drops objects created before the cutoff", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/withdrawals", fn conn ->
        items = [
          withdrawal_json("wtd_new", "payout=a", unix("2026-07-20T12:00:00Z")),
          withdrawal_json("wtd_old", "payout=b", unix("2026-01-01T12:00:00Z"))
        ]

        Plug.Conn.resp(conn, 200, page_json(items, 1))
      end)

      assert {:ok, [%{uid: "wtd_new"}]} = OPP.list_recent_withdrawals(~U[2026-07-01 00:00:00Z])
    end

    test "keeps paging while every object on the page is within the window",
         %{bypass: bypass} do
      Agent.start_link(fn -> [] end, name: :opp_pages)

      Bypass.expect(bypass, "GET", "/withdrawals", fn conn ->
        %{"page" => page} = URI.decode_query(conn.query_string)
        Agent.update(:opp_pages, &[page | &1])

        item = withdrawal_json("wtd_#{page}", "payout=#{page}", unix("2026-07-20T12:00:00Z"))
        Plug.Conn.resp(conn, 200, page_json([item], 3))
      end)

      assert {:ok, withdrawals} = OPP.list_recent_withdrawals(~U[2026-07-01 00:00:00Z])

      assert Enum.map(withdrawals, & &1.uid) == ["wtd_1", "wtd_2", "wtd_3"]
      assert Agent.get(:opp_pages, &Enum.reverse/1) == ["1", "2", "3"]
    end

    test "stops paging at the first page containing an object past the cutoff",
         %{bypass: bypass} do
      Agent.start_link(fn -> 0 end, name: :opp_page_count)

      Bypass.expect(bypass, "GET", "/withdrawals", fn conn ->
        Agent.update(:opp_page_count, &(&1 + 1))

        items = [
          withdrawal_json("wtd_new", "payout=a", unix("2026-07-20T12:00:00Z")),
          withdrawal_json("wtd_old", "payout=b", unix("2026-01-01T12:00:00Z"))
        ]

        Plug.Conn.resp(conn, 200, page_json(items, 10))
      end)

      assert {:ok, [%{uid: "wtd_new"}]} = OPP.list_recent_withdrawals(~U[2026-07-01 00:00:00Z])
      assert Agent.get(:opp_page_count, & &1) == 1
    end

    test "requests newest-first ordering", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/withdrawals", fn conn ->
        assert conn.query_string =~ "order[]=-date_created"
        Plug.Conn.resp(conn, 200, page_json([], 1))
      end)

      assert {:ok, []} = OPP.list_recent_withdrawals(~U[2026-07-01 00:00:00Z])
    end

    test "surfaces an OPP API error on non-2xx", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/withdrawals", fn conn ->
        Plug.Conn.resp(conn, 500, ~s<{"error": {"message": "nope"}}>)
      end)

      assert {:error, %Error{code: :api_error}} =
               OPP.list_recent_withdrawals(~U[2026-07-01 00:00:00Z])
    end
  end

  describe "list_recent_transfers/1" do
    test "reads the payout reference back out of charge metadata", %{bypass: bypass} do
      # A charge has no `reference` field of its own — transfer_to_merchant/4
      # writes the idempotence key into metadata, and OPP returns metadata as a
      # list of key/value pairs rather than the object it was written as.
      Bypass.expect_once(bypass, "GET", "/charges", fn conn ->
        item =
          ~s<{"uid": "chg_1", "object": "charge", "status": "completed", "amount": 500, > <>
            ~s<"created": 1785329635, > <>
            ~s<"metadata": [{"key": "reference", "value": "payout=abc,type=transfer"}]}>

        Plug.Conn.resp(conn, 200, ~s<{"object": "list", "last_page": 1, "data": [#{item}]}>)
      end)

      assert {:ok, [%{uid: "chg_1", reference: "payout=abc,type=transfer", amount: 500}]} =
               OPP.list_recent_transfers(~U[2026-07-01 00:00:00Z])
    end

    test "leaves the reference nil when the charge carries no metadata", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/charges", fn conn ->
        item =
          ~s<{"uid": "chg_2", "object": "charge", "status": "completed", "amount": 500, > <>
            ~s<"created": 1785329635, "metadata": []}>

        Plug.Conn.resp(conn, 200, ~s<{"object": "list", "last_page": 1, "data": [#{item}]}>)
      end)

      assert {:ok, [%{uid: "chg_2", reference: nil}]} =
               OPP.list_recent_transfers(~U[2026-07-01 00:00:00Z])
    end
  end
end
