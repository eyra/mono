# `Next.Systems.Paper.RISParserStream`
[🔗](https://github.com/eyra/mono/blob/main/next/systems/paper/ris_parser_stream.ex#L1)

Streaming RIS parser that processes records one at a time without loading
the entire file into memory. Designed for handling large files with 100k+ references.

# `parse_stream`

Parse a stream of RIS content, yielding parsed references one at a time.

Returns a stream that emits {:ok, {attrs, raw}} or {:error, {error, raw}} for each reference.
This allows processing millions of references without loading them all into memory.

# `parse_stream_with_validation`

Validate and parse a stream with early termination on critical errors.
Applies validation before parsing to catch binary files, encoding issues, etc.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
