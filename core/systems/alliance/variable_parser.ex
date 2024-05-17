defmodule Systems.Alliance.VariableParser do
  @dialyzer {:nowarn_function, parse: 1}

  import NimbleParsec

  variable =
    string("{")
    |> ignore()
    |> utf8_string([?a..?z, ?A..?Z], min: 1)
    |> tag(:variable)
    |> concat(string("}") |> ignore())
    |> label("variable (ex. {participantId}")

  non_variable =
    [{:not, 0x007B}, {:not, 0x007D}]
    |> ascii_char()
    |> repeat()
    |> tag(:plain)
    |> label("plain")

  defparsec(:parse, choice([variable, non_variable]) |> eos())
end
