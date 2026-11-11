# `MicaWeb.Cldr.Rbnf.Spellout`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Functions to implement the spellout rule-based-number-format rules of CLDR.

As CLDR notes, the data is incomplete or non-existent for many languages.  It
is considered complete for English however.

The standard public API for RBNF is via the `Cldr.Number.to_string/2` function.

The functions on this module are defined at compile time based upon the RBNF rules
defined in the Unicode CLDR data repository.  Available rules are identified by:

    iex> MicaWeb.Cldr.Rbnf.Spellout.rule_sets("en")
    ...> |> Enum.sort()
    [
      :spellout_cardinal,
      :spellout_cardinal_verbose,
      :spellout_numbering,
      :spellout_numbering_verbose,
      :spellout_numbering_year,
      :spellout_ordinal,
      :spellout_ordinal_verbose
    ]

A rule can then be invoked on an available rule_set. For example:

    iex> MicaWeb.Cldr.Rbnf.Spellout.spellout_ordinal(123, "en")
    "one hundred twenty-third"

This call is equivalent to the call through the public API of:

    iex> MicaWeb.Cldr.Number.to_string(123, format: :spellout)
    {:ok, "one hundred twenty-three"}

# `all_rule_sets`

# `and`

# `and_o`

# `commas`

# `commas_o`

# `fem_with_a`

# `fem_with_i`

# `fem_with_o`

# `fractions_feminine`

# `fractions_feminine_accusative`

# `fractions_feminine_dative`

# `fractions_feminine_genitive`

# `fractions_feminine_instrumental`

# `fractions_feminine_locative`

# `lenient_parse`

# `msc_no_final`

# `msc_with_a`

# `msc_with_a_nofinal`

# `msc_with_i`

# `msc_with_i_nofinal`

# `msc_with_o`

# `msc_with_o_nofinal`

# `msco_with_a`

# `msco_with_i`

# `msco_with_o`

# `number_en`

# `ord_ste`

# `ordinal_esima`

# `ordinal_esima_with_a`

# `ordinal_esima_with_i`

# `ordinal_esima_with_o`

# `ordinal_esime`

# `ordinal_esime_with_a`

# `ordinal_esime_with_i`

# `ordinal_esime_with_o`

# `ordinal_esimi`

# `ordinal_esimi_with_a`

# `ordinal_esimi_with_i`

# `ordinal_esimi_with_o`

# `ordinal_esimo`

# `ordinal_esimo_with_a`

# `ordinal_esimo_with_i`

# `ordinal_esimo_with_o`

# `r2d_year`

# `rule_sets`

# `rule_sets`

# `spellout_cardinal`

# `spellout_cardinal_feminine`

# `spellout_cardinal_feminine_accusative`

# `spellout_cardinal_feminine_dative`

# `spellout_cardinal_feminine_genitive`

# `spellout_cardinal_feminine_instrumental`

# `spellout_cardinal_feminine_locative`

# `spellout_cardinal_m`

# `spellout_cardinal_masculine`

# `spellout_cardinal_masculine_accusative`

# `spellout_cardinal_masculine_dative`

# `spellout_cardinal_masculine_genitive`

# `spellout_cardinal_masculine_instrumental`

# `spellout_cardinal_masculine_locative`

# `spellout_cardinal_n`

# `spellout_cardinal_neuter`

# `spellout_cardinal_r`

# `spellout_cardinal_s`

# `spellout_cardinal_stem_few`

# `spellout_cardinal_stressed`

# `spellout_cardinal_verbose`

# `spellout_numbering`

# `spellout_numbering_verbose`

# `spellout_numbering_year`

# `spellout_ordinal`

# `spellout_ordinal_base`

# `spellout_ordinal_base_i`

# `spellout_ordinal_feminine`

# `spellout_ordinal_feminine_accusative`

# `spellout_ordinal_feminine_dative`

# `spellout_ordinal_feminine_genitive`

# `spellout_ordinal_feminine_instrumental`

# `spellout_ordinal_feminine_locative`

# `spellout_ordinal_feminine_plural`

# `spellout_ordinal_feminine_plural_accusative`

# `spellout_ordinal_feminine_plural_dative`

# `spellout_ordinal_feminine_plural_genitive`

# `spellout_ordinal_feminine_plural_instrumental`

# `spellout_ordinal_feminine_plural_locative`

# `spellout_ordinal_m`

# `spellout_ordinal_masculine`

# `spellout_ordinal_masculine_accusative`

# `spellout_ordinal_masculine_adjective`

# `spellout_ordinal_masculine_dative`

# `spellout_ordinal_masculine_genitive`

# `spellout_ordinal_masculine_instrumental`

# `spellout_ordinal_masculine_locative`

# `spellout_ordinal_masculine_plural`

# `spellout_ordinal_masculine_plural_accusative`

# `spellout_ordinal_masculine_plural_dative`

# `spellout_ordinal_masculine_plural_genitive`

# `spellout_ordinal_masculine_plural_instrumental`

# `spellout_ordinal_masculine_plural_locative`

# `spellout_ordinal_n`

# `spellout_ordinal_neuter`

# `spellout_ordinal_r`

# `spellout_ordinal_s`

# `spellout_ordinal_verbose`

# `ste2`

# `ste`

# `th`

# `tieth`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
