# `MicaWeb.Cldr.Rbnf.Ordinal`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Functions to implement the ordinal rule-based-number-format rules of CLDR.

As CLDR notes, the data is incomplete or non-existent for many languages.  It
is considered complete for English however.

The standard public API for RBNF is via the `Cldr.Number.to_string/2` function.

The functions on this module are defined at compile time based upon the RBNF rules
defined in the Unicode CLDR data repository.  Available rules are identified by:

    iex> MicaWeb.Cldr.Rbnf.Ordinal.rule_sets(:en)
    [:digits_ordinal]

    iex> MicaWeb.Cldr.Rbnf.Ordinal.rule_sets("fr")
    ...> |> Enum.sort()
    [
      :digits_ordinal,
      :digits_ordinal_feminine,
      :digits_ordinal_feminine_plural,
      :digits_ordinal_masculine,
      :digits_ordinal_masculine_plural
    ]

A rule can then be invoked on an available rule_set.  For example

    iex> MicaWeb.Cldr.Rbnf.Ordinal.digits_ordinal(123, :en)
    "123rd"

This call is equivalent to the call through the public API of:

    iex> MicaWeb.Cldr.Number.to_string(123, format: :ordinal)
    {:ok, "123rd"}

# `all_rule_sets`

# `digits_ordinal`

# `digits_ordinal_feminine`

# `digits_ordinal_feminine_plural`

# `digits_ordinal_masculine`

# `digits_ordinal_masculine_adjective`

# `digits_ordinal_masculine_plural`

# `dord_femabbrev`

# `dord_mascabbrev`

# `rule_sets`

# `rule_sets`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
