# `Frameworks.Utility.HTTPClient`
[🔗](https://github.com/eyra/mono/blob/main/mica/frameworks/utility/http_client.ex#L1)

# `body`

```elixir
@type body() :: HTTPoison.Base.body()
```

# `headers`

```elixir
@type headers() :: HTTPoison.Base.headers()
```

# `method`

```elixir
@type method() :: HTTPoison.Base.method()
```

# `options`

```elixir
@type options() :: HTTPoison.Base.options()
```

# `params`

```elixir
@type params() :: HTTPoison.Base.params()
```

# `request`

```elixir
@type request() :: HTTPoison.Base.request()
```

# `url`

```elixir
@type url() :: HTTPoison.Base.url()
```

# `delete`

```elixir
@spec delete(binary(), headers(), Keyword.t()) ::
  {:ok,
   HTTPoison.Response.t()
   | HTTPoison.AsyncResponse.t()
   | HTTPoison.MaybeRedirect.t()}
  | {:error, HTTPoison.Error.t()}
```

Issues a DELETE request to the given url.

Returns `{:ok, response}` if the request is successful, `{:error, reason}`
otherwise.

See `request/5` for more detailed information.

# `delete!`

```elixir
@spec delete!(binary(), headers(), Keyword.t()) ::
  HTTPoison.Response.t()
  | HTTPoison.AsyncResponse.t()
  | HTTPoison.MaybeRedirect.t()
```

Issues a DELETE request to the given url, raising an exception in case of
failure.

If the request does not fail, the response is returned.

See `request!/5` for more detailed information.

# `get`

```elixir
@spec get(binary(), headers(), Keyword.t()) ::
  {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
  | {:error, HTTPoison.Error.t()}
```

Issues a GET request to the given url.

Returns `{:ok, response}` if the request is successful, `{:error, reason}`
otherwise.

See `request/5` for more detailed information.

# `get!`

```elixir
@spec get!(binary(), headers(), Keyword.t()) ::
  HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()
```

Issues a GET request to the given url, raising an exception in case of
failure.

If the request does not fail, the response is returned.

See `request!/5` for more detailed information.

# `head`

```elixir
@spec head(binary(), headers(), Keyword.t()) ::
  {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
  | {:error, HTTPoison.Error.t()}
```

Issues a HEAD request to the given url.

Returns `{:ok, response}` if the request is successful, `{:error, reason}`
otherwise.

See `request/5` for more detailed information.

# `head!`

```elixir
@spec head!(binary(), headers(), Keyword.t()) ::
  HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()
```

Issues a HEAD request to the given url, raising an exception in case of
failure.

If the request does not fail, the response is returned.

See `request!/5` for more detailed information.

# `options`

```elixir
@spec options(binary(), headers(), Keyword.t()) ::
  {:ok,
   HTTPoison.Response.t()
   | HTTPoison.AsyncResponse.t()
   | HTTPoison.MaybeRedirect.t()}
  | {:error, HTTPoison.Error.t()}
```

Issues an OPTIONS request to the given url.

Returns `{:ok, response}` if the request is successful, `{:error, reason}`
otherwise.

See `request/5` for more detailed information.

# `options!`

```elixir
@spec options!(binary(), headers(), Keyword.t()) ::
  HTTPoison.Response.t()
  | HTTPoison.AsyncResponse.t()
  | HTTPoison.MaybeRedirect.t()
```

Issues a OPTIONS request to the given url, raising an exception in case of
failure.

If the request does not fail, the response is returned.

See `request!/5` for more detailed information.

# `patch`

```elixir
@spec patch(binary(), any(), headers(), Keyword.t()) ::
  {:ok,
   HTTPoison.Response.t()
   | HTTPoison.AsyncResponse.t()
   | HTTPoison.MaybeRedirect.t()}
  | {:error, HTTPoison.Error.t()}
```

Issues a PATCH request to the given url.

Returns `{:ok, response}` if the request is successful, `{:error, reason}`
otherwise.

See `request/5` for more detailed information.

# `patch!`

```elixir
@spec patch!(binary(), any(), headers(), Keyword.t()) ::
  HTTPoison.Response.t()
  | HTTPoison.AsyncResponse.t()
  | HTTPoison.MaybeRedirect.t()
```

Issues a PATCH request to the given url, raising an exception in case of
failure.

If the request does not fail, the response is returned.

See `request!/5` for more detailed information.

# `post`

```elixir
@spec post(binary(), any(), headers(), Keyword.t()) ::
  {:ok,
   HTTPoison.Response.t()
   | HTTPoison.AsyncResponse.t()
   | HTTPoison.MaybeRedirect.t()}
  | {:error, HTTPoison.Error.t()}
```

Issues a POST request to the given url.

Returns `{:ok, response}` if the request is successful, `{:error, reason}`
otherwise.

See `request/5` for more detailed information.

# `post!`

```elixir
@spec post!(binary(), any(), headers(), Keyword.t()) ::
  HTTPoison.Response.t()
  | HTTPoison.AsyncResponse.t()
  | HTTPoison.MaybeRedirect.t()
```

Issues a POST request to the given url, raising an exception in case of
failure.

If the request does not fail, the response is returned.

See `request!/5` for more detailed information.

# `process_headers`

> This function is deprecated. Use process_response_headers/1 instead.

```elixir
@spec process_headers(list()) :: any()
```

# `process_request_headers`

```elixir
@spec process_request_headers(headers()) :: headers()
```

# `process_request_options`

```elixir
@spec process_request_options(options()) :: options()
```

# `process_request_params`

```elixir
@spec process_request_params(params()) :: params()
```

# `process_request_url`

```elixir
@spec process_request_url(url()) :: url()
```

# `process_response`

```elixir
@spec process_response(HTTPoison.Base.response()) :: any()
```

# `process_response_body`

```elixir
@spec process_response_body(binary()) :: any()
```

# `process_response_chunk`

```elixir
@spec process_response_chunk(binary()) :: any()
```

# `process_response_headers`

```elixir
@spec process_response_headers(list()) :: any()
```

# `process_response_status_code`

```elixir
@spec process_response_status_code(integer()) :: any()
```

# `process_status_code`

> This function is deprecated. Use process_response_status_code/1 instead.

```elixir
@spec process_status_code(integer()) :: any()
```

# `process_url`

> This function is deprecated. Use process_request_url/1 instead.

```elixir
@spec process_url(url()) :: url()
```

# `put`

```elixir
@spec put(binary(), any(), headers(), Keyword.t()) ::
  {:ok,
   HTTPoison.Response.t()
   | HTTPoison.AsyncResponse.t()
   | HTTPoison.MaybeRedirect.t()}
  | {:error, HTTPoison.Error.t()}
```

Issues a PUT request to the given url.

Returns `{:ok, response}` if the request is successful, `{:error, reason}`
otherwise.

See `request/5` for more detailed information.

# `put!`

```elixir
@spec put!(binary(), any(), headers(), Keyword.t()) ::
  HTTPoison.Response.t()
  | HTTPoison.AsyncResponse.t()
  | HTTPoison.MaybeRedirect.t()
```

Issues a PUT request to the given url, raising an exception in case of
failure.

If the request does not fail, the response is returned.

See `request!/5` for more detailed information.

# `request`

```elixir
@spec request(HTTPoison.Request.t()) ::
  {:ok,
   HTTPoison.Response.t()
   | HTTPoison.AsyncResponse.t()
   | HTTPoison.MaybeRedirect.t()}
  | {:error, HTTPoison.Error.t()}
```

Issues an HTTP request using an `HTTPoison.Request` struct.

This function returns `{:ok, response}` or `{:ok, async_response}`
if the request is successful, `{:error, reason}` otherwise.

## Redirect handling

If the option `:follow_redirect` is given, HTTP redirects are followed
internally by hackney when the method is `:get` or `:head` and the
response's `status_code` is `301`, `302` or `307`, and when the method is
`:post` and the `status_code` is `303`. Redirects are resolved up to
`:max_redirect` hops and the final response is returned.

As of hackney 4.0 redirects are resolved inside hackney, so a
`HTTPoison.MaybeRedirect` is no longer returned. The struct is retained
only for backward compatibility.

## Examples

    request = %HTTPoison.Request{
      method: :post,
      url: "https://my.website.com",
      body: "{\"foo\": 3}",
      headers: [{"Accept", "application/json"}]
    }

    request(request)

# `request`

```elixir
@spec request(method(), binary(), any(), headers(), Keyword.t()) ::
  {:ok,
   HTTPoison.Response.t()
   | HTTPoison.AsyncResponse.t()
   | HTTPoison.MaybeRedirect.t()}
  | {:error, HTTPoison.Error.t()}
```

Issues an HTTP request with the given method to the given url.

This function is usually used indirectly by `get/3`, `post/4`, `put/4`, etc

Args:
  * `method` - HTTP method as an atom (`:get`, `:head`, `:post`, `:put`,
    `:delete`, etc.)
  * `url` - target url as a binary string or char list
  * `body` - request body. See more below
  * `headers` - HTTP headers as an orddict (e.g., `[{"Accept", "application/json"}]`)
  * `options` - Keyword list of options

Body: see type `HTTPoison.Request`

Options: see type `HTTPoison.Request`

This function returns `{:ok, response}` or `{:ok, async_response}`
if the request is successful, `{:error, reason}` otherwise.

## Redirect handling

If the option `:follow_redirect` is given, HTTP redirects are followed
internally by hackney when the method is `:get` or `:head` and the
response's `status_code` is `301`, `302` or `307`, and when the method is
`:post` and the `status_code` is `303`. Redirects are resolved up to
`:max_redirect` hops and the final response is returned.

As of hackney 4.0 redirects are resolved inside hackney, so a
`HTTPoison.MaybeRedirect` is no longer returned. The struct is retained
only for backward compatibility.

## Examples

    request(:post, "https://my.website.com", "{\"foo\": 3}", [{"Accept", "application/json"}])

# `request!`

```elixir
@spec request!(HTTPoison.Request.t()) ::
  HTTPoison.Response.t()
  | HTTPoison.AsyncResponse.t()
  | HTTPoison.MaybeRedirect.t()
```

Issues an HTTP request an `HTTPoison.Request` struct.
exception in case of failure.

`request!/1` works exactly like `request/1` but it returns just the
response in case of a successful request, raising an exception in case the
request fails.

# `request!`

```elixir
@spec request!(method(), binary(), any(), headers(), Keyword.t()) ::
  HTTPoison.Response.t()
  | HTTPoison.AsyncResponse.t()
  | HTTPoison.MaybeRedirect.t()
```

Issues an HTTP request with the given method to the given url, raising an
exception in case of failure.

`request!/5` works exactly like `request/5` but it returns just the
response in case of a successful request, raising an exception in case the
request fails.

# `start`

Starts HTTPoison and its dependencies.

# `stream_next`

```elixir
@spec stream_next(HTTPoison.AsyncResponse.t()) ::
  {:ok, HTTPoison.AsyncResponse.t()} | {:error, HTTPoison.Error.t()}
```

Requests the next message to be streamed for a given `HTTPoison.AsyncResponse`.

See `request!/5` for more detailed information.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
