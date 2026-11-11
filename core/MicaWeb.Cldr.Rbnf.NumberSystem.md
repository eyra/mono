# `MicaWeb.Cldr.Rbnf.NumberSystem`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/cldr.ex#L1)

Functions to implement the number system rule-based-number-format rules of CLDR.

These rules are defined only on the "und" locale and represent specialised
number formatting.

The standard public API for RBNF is via the `Cldr.Number.to_string/2` function.

The functions on this module are defined at compile time based upon the RBNF rules
defined in the Unicode CLDR data repository.  Available rules are identified by:

    iex> MicaWeb.Cldr.Rbnf.NumberSystem.rule_sets(:und)
    ...> |> Enum.sort()
    [
      :armenian_lower,
      :armenian_upper,
      :cyrillic_lower,
      :ethiopic,
      :georgian,
      :greek_lower,
      :greek_upper,
      :hebrew,
      :hebrew_item,
      :roman_lower,
      :roman_upper,
      :tamil,
      :zz_default
    ]

A rule can then be invoked on an available rule_set.  For example

    iex> MicaWeb.Cldr.Rbnf.NumberSystem.roman_upper(123, :und)
    "CXXIII"

This particular call is equivalent to the call through the public API of:

    iex> MicaWeb.Cldr.Number.to_string(123, format: :roman)
    {:ok, "CXXIII"}

# `all_rule_sets`

# `armenian_lower`

# `armenian_lower`

# `armenian_upper`

# `armenian_upper`

# `cyrillic_lower`

# `cyrillic_lower`

# `cyrillic_lower_1_10`

# `cyrillic_lower_final`

# `cyrillic_lower_post`

# `cyrillic_lower_thousands`

# `ethiopic`

# `ethiopic`

# `ethiopic_p1`

# `ethiopic_p2`

# `ethiopic_p3`

# `ethiopic_p`

# `georgian`

# `georgian`

# `greek_lower`

# `greek_lower`

# `greek_numeral_majuscules`

# `greek_numeral_minuscules`

# `greek_upper`

# `greek_upper`

# `hebrew`

# `hebrew`

# `hebrew_0_99`

# `hebrew_item`

# `hebrew_item`

# `hebrew_item_hundreds`

# `hebrew_thousands`

# `roman_lower`

# `roman_lower`

# `roman_upper`

# `roman_upper`

# `rule_sets`

# `rule_sets`

# `tamil`

# `tamil`

# `tamil_thousands`

# `zz_default`

# `zz_default`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
