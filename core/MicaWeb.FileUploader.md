# `MicaWeb.FileUploader`
[🔗](https://github.com/eyra/mono/blob/main/mica/lib/mica_web/file_uploader.ex#L1)

# `file_upload_error`
*optional* 

```elixir
@callback file_upload_error(socket :: Phoenix.LiveView.Socket.t(), reason :: any()) ::
  Phoenix.LiveView.Socket.t()
```

# `file_upload_progress`
*optional* 

```elixir
@callback file_upload_progress(socket :: Phoenix.LiveView.Socket.t(), info :: any()) ::
  Phoenix.LiveView.Socket.t()
```

# `file_upload_start`
*optional* 

```elixir
@callback file_upload_start(socket :: Phoenix.LiveView.Socket.t(), info :: any()) ::
  Phoenix.LiveView.Socket.t()
```

# `pre_process_file`
*optional* 

```elixir
@callback pre_process_file(info :: any()) :: map()
```

# `process_file`

```elixir
@callback process_file(socket :: Phoenix.LiveView.Socket.t(), info :: any()) ::
  Phoenix.LiveView.Socket.t()
```

# `get_upload_path`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
