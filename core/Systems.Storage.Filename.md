# `Systems.Storage.Filename`
[🔗](https://github.com/eyra/mono/blob/main/mica/systems/storage/filename.ex#L1)

Generates filenames for storage backends.

# `generate`

Generates a filename from an identifier list.

Example: assignment=5_task=9.json

# `generate_unique`

Generates a unique filename with timestamp. The unique integer keeps names
apart that are generated in the same millisecond, such as a trial and its
Prompt result donated at once.

# `url_segment`

Turns a filename into a single URL path segment: `/` and `\` become `_`, so
the file stays in the endpoint's folder, and every character outside RFC 3986
`pchar` is percent-encoded. The server decodes it back to the same name.
A whole name of `.` or `..` stays a dot segment; `generate/1` never returns
one, as its names always end in `.json`.

# `valid_identifier?`

Returns true when every identifier value is nil, an integer, or a string
without control characters (such as CR, LF or NUL). Donation keys, tasks and
sources never need them. Any other value, such as a list or a map, is refused.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
