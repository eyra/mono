defmodule Systems.Alliance.VariableParser do
  @moduledoc false
  import NimbleParsec

  @dialyzer {:nowarn_function, parse: 1}

  variable =
    "{"
    |> string()
    |> ignore()
    |> utf8_string([?a..?z, ?A..?Z], min: 1)
    |> tag(:variable)
    |> concat("}" |> string() |> ignore())
    |> label("variable (ex. {participantId}")

  non_variable =
    [{:not, 0x007B}, {:not, 0x007D}]
    |> ascii_char()
    |> repeat()
    |> tag(:plain)
    |> label("plain")

  defparsec(:parse, [variable, non_variable] |> choice() |> eos())
end
