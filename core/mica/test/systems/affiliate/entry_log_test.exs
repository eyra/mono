defmodule Systems.Affiliate.EntryLogTest do
  use MicaWeb.ConnCase, async: false

  import ExUnit.CaptureLog

  alias Systems.Assignment
  alias Systems.Affiliate

  @panel_value "panel-secret-value-4711"

  describe "GET /a/:sqid refused entries" do
    test "an invalid sqid logs the reason, not the participant or panel values", %{conn: conn} do
      participant_id = "participant-secret-4711"

      {conn, log} =
        with_log(fn ->
          get(conn, "/a/invalid_sqid_123?p=#{participant_id}&panel=#{@panel_value}")
        end)

      assert conn.status == 403
      refute log =~ participant_id
      refute log =~ @panel_value
      assert log =~ "Invalid sqid"
    end

    test "a sqid with a newline logs on one line, escaped", %{conn: conn} do
      {conn, log} =
        with_log(fn ->
          get(conn, "/a/abc%0Aforged-entry?p=participant-1")
        end)

      assert conn.status == 403
      refute log =~ "\nforged-entry"
      assert log =~ ~S(abc\nforged-entry)
    end

    test "a param key with a newline logs on one line, escaped", %{conn: conn} do
      {conn, log} =
        with_log(fn ->
          get(conn, "/a/invalid_sqid_123?p=participant-1&key%0Aforged-entry=1")
        end)

      assert conn.status == 403
      refute log =~ "\nforged-entry"
      assert log =~ ~S(key\nforged-entry)
    end

    test "an invalid participant id logs the reason, not the participant or panel values",
         %{conn: conn} do
      assignment = Assignment.Factories.create_assignment_with_affiliate()
      sqid = Affiliate.Sqids.encode!([0, assignment.id])
      participant_id = "jane.doe@example.org"

      {conn, log} =
        with_log(fn ->
          get(conn, "/a/#{sqid}?p=#{URI.encode_www_form(participant_id)}&panel=#{@panel_value}")
        end)

      assert conn.status == 403
      refute log =~ participant_id
      refute log =~ @panel_value
      assert log =~ "invalid participant id"
    end

    test "a sqid for another resource logs the reason, not the participant or panel values",
         %{conn: conn} do
      sqid = Affiliate.Sqids.encode!([1, 42])
      participant_id = "participant-secret-4711"

      {conn, log} =
        with_log(fn ->
          get(conn, "/a/#{sqid}?p=#{participant_id}&panel=#{@panel_value}")
        end)

      assert conn.status == 403
      refute log =~ participant_id
      refute log =~ @panel_value
      assert log =~ "unexpected sqid"
    end
  end

  describe "GET /r/:sqid refused entries" do
    test "a sqid with a newline logs on one line, escaped", %{conn: conn} do
      {conn, log} =
        with_log(fn ->
          get(conn, "/r/abc%0Aforged-entry")
        end)

      assert conn.status == 403
      refute log =~ "\nforged-entry"
      assert log =~ ~S(abc\nforged-entry)
    end
  end
end
