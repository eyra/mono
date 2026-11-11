# `Frameworks.Utility.PackmaticURLSource`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/utility/packmatic_url_source.ex#L1)

Packmatic source that downloads a URL, used instead of Packmatic's own
`{:url, url}` source. Use it in a manifest entry as
`source: {Frameworks.Utility.PackmaticURLSource, url}` or
`{Frameworks.Utility.PackmaticURLSource, {url, max_bytes: n}}`.

Packmatic 2.1's URL reader crashes (`function_clause`) on a response without
a body, and the crash takes the process that builds the zip down with it. This
source handles those cases as results:

  * a 200 response is the entry's content, an empty body included;
  * any other status, redirects included, fails the entry with `{:http_status, status}`;
  * with `max_bytes`, more data than that fails it with `{:too_large, max_bytes}`.

The download runs in an unlinked task that hands over one chunk at a time and
waits until it is read, so a slow zip consumer never piles chunks up in memory.
Retries are off: a retried download would repeat chunks already in the zip.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
