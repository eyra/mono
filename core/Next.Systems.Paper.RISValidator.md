# `Next.Systems.Paper.RISValidator`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/paper/ris_validator.ex#L1)

Validates RIS files before parsing to prevent crashes from invalid files.

# `is_binary_content?`

Check if content appears to be binary (not text).
Exposed for streaming validation.

# `validate_content`

Validates RIS content before parsing.
Returns {:ok, content} if valid, {:error, reason} if invalid.

# `validate_with_timeout`

Validates RIS content with a timeout to prevent hanging on malformed files.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
