defmodule Systems.Feldspar.Plug do
  @moduledoc false
  @behaviour Plug

  alias Systems.Feldspar.LocalFS

  defmacro setup() do
    quote do
      plug(Systems.Feldspar.Plug, at: Systems.Feldspar.LocalFS.public_path())
    end
  end

  @impl true
  def init(opts) do
    opts
    # Ensure that init works, from will be set dynamically later on
    |> Keyword.put(:from, {nil, nil})
    |> Plug.Static.init()
  end

  @impl true
  def call(conn, options) do
    call(Systems.Feldspar.Private.get_backend(), conn, options)
  end

  def call(LocalFS, conn, options) do
    root_path = LocalFS.get_root_path()
    options = Map.put(options, :from, root_path)
    Plug.Static.call(conn, options)
  end

  def call(_, conn, _options), do: conn
end
