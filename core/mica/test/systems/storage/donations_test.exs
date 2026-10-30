defmodule Systems.Storage.DonationsTest do
  use ExUnit.Case, async: true

  alias Systems.Storage.Donations

  @path "assignment=5_task=9_participant=ab_c_source=cogflex_key=run1/cogflex/practice2/0.json"

  describe "participant/1" do
    test "reads a participant id that contains an underscore" do
      assert Donations.participant(@path) == "ab_c"
    end

    test "reads the participant when there is no source" do
      assert Donations.participant("assignment=5_participant=p1_key=run1/summary.json") == "p1"
    end

    test "reads the participant when there is no key" do
      assert Donations.participant("assignment=5_participant=p1.json") == "p1"
    end

    test "ignores a participant=-like part of the key" do
      assert Donations.participant("assignment=5_key=participant=p1.json") == nil
    end

    test "is nil without a participant" do
      assert Donations.participant("assignment=5_task=9_key=run1/summary.json") == nil
    end
  end

  describe "key/1" do
    test "reads the key, slashes included" do
      assert Donations.key(@path) == "run1/cogflex/practice2/0"
    end

    test "is nil without a key" do
      assert Donations.key("assignment=5_participant=p1.json") == nil
    end
  end

  describe "session/1" do
    test "is the part of the key before the first slash" do
      assert Donations.session(@path) == "run1"
    end

    test "is the part of a key without slash before the first dash" do
      assert Donations.session("participant=p1_key=1793001234567-tiktok.json") == "1793001234567"
    end

    test "keeps the dashes of a run id before the first slash" do
      assert Donations.session("participant=p1_key=6e455c88-7dde-4e6e/summary.json") ==
               "6e455c88-7dde-4e6e"
    end

    test "is the whole key when the key has neither slash nor dash" do
      assert Donations.session("participant=p1_key=summary.json") == "summary"
    end

    test "is nil without a key" do
      assert Donations.session("participant=p1.json") == nil
    end
  end

  describe "tool/1" do
    test "is the source" do
      assert Donations.tool(@path) == "cogflex"
    end

    test "is the task without a source" do
      assert Donations.tool("assignment=5_task=9_participant=p1_key=run1/summary.json") == "9"
    end

    test "is nil without source and task" do
      assert Donations.tool("participant=p1_key=run1/summary.json") == nil
    end
  end

  describe "by_participant/1" do
    test "groups files per participant" do
      files = [
        %{path: "participant=b_key=r1/x.json"},
        %{path: "participant=a_key=r1/x.json"},
        %{path: "participant=b_key=r2/x.json"}
      ]

      assert [{"a", [_]}, {"b", [_, _]}] = Donations.by_participant(files)
    end

    test "puts files without a participant last" do
      files = [%{path: "key=r1/x.json"}, %{path: "participant=a_key=r1/x.json"}]

      assert [{"a", _}, {nil, [%{path: "key=r1/x.json"}]}] = Donations.by_participant(files)
    end
  end

  describe "summaries/1" do
    test "counts sessions, tools and files per participant, with the last donation" do
      earlier = ~U[2026-10-29 09:00:00Z]
      later = ~U[2026-10-29 10:00:00Z]

      files = [
        %{path: "participant=p1_source=cogflex_key=r1/cogflex/a/0.json", timestamp: earlier},
        %{path: "participant=p1_source=cogflex_key=r1/summary.json", timestamp: later},
        %{path: "participant=p1_source=rbmt_key=r2/summary.json", timestamp: earlier}
      ]

      assert [
               %{
                 participant: "p1",
                 sessions: 2,
                 tools: ["cogflex", "rbmt"],
                 files: 3,
                 last_donation: ^later
               }
             ] = Donations.summaries(files)
    end

    test "skips a missing timestamp for the last donation" do
      files = [%{path: "participant=p1_key=r1/summary.json", timestamp: nil}]

      assert [%{last_donation: nil}] = Donations.summaries(files)
    end
  end
end
