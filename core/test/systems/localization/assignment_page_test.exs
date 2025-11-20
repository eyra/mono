defmodule Systems.Localization.AssignmentLanguageEnforcedTest do
  use ExUnit.Case, async: true

  alias Systems.Localization.Resolvers.AssignmentLanguageEnforced
  alias Systems.Assignment

  test "picks assignment language when available" do
    info = %Assignment.InfoModel{language: :nl}

    locale =
      AssignmentLanguageEnforced.resolve_locale(
        assignment: info,
        default_locale: "en"
      )

    assert locale == "nl"
  end

  test "defaults to EN when nothing else is available" do
    locale =
      AssignmentLanguageEnforced.resolve_locale(assignment: nil)

    assert locale == "en"
  end
end
