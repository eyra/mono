defmodule Systems.Storage.Controller do
  alias CoreWeb.UI.Timestamp
  use CoreWeb, :controller

  alias Frameworks.Concept.Molecule

  alias Systems.Storage
  alias Systems.Rate

  def export(conn, %{"id" => id}) do
    if endpoint =
         Storage.Public.get_endpoint!(
           String.to_integer(id),
           Storage.EndpointModel.preload_graph(:down)
         ) do
      special = Storage.EndpointModel.special(endpoint)
      molecule_name = Molecule.name(endpoint, :parent, "export")

      export(conn, special, molecule_name)
    else
      service_unavailable(conn)
    end
  end

  def export(
        %{remote_ip: remote_ip} = conn,
        %Storage.BuiltIn.EndpointModel{} = builtin,
        molecule_name
      ) do
    date = Timestamp.now() |> Timestamp.format_date_short!()

    export_name =
      [date, molecule_name]
      |> Enum.join(" ")
      |> Slug.slugify(separator: ?_)

    builtin
    |> Storage.BuiltIn.Backend.list_files()
    |> request_permission(remote_ip)
    |> Enum.map(fn %{url: url, path: path, timestamp: timestamp} ->
      [source: {:url, url}, path: "#{export_name}/#{path}", timestamp: timestamp]
    end)
    |> Packmatic.build_stream()
    |> Packmatic.Conn.send_chunked(conn, "#{export_name}.zip")
  end

  def export(conn, _, _) do
    service_unavailable(conn)
  end

  defp request_permission(files, remote_ip) when is_list(files) do
    size = Enum.reduce(files, 0, fn %{size: size}, acc -> acc + size end)
    remote_ip = to_string(:inet_parse.ntoa(remote_ip))
    # raises error when request is denied
    Rate.Public.request_permission(:storage_export, remote_ip, size)
    files
  end

  defp service_unavailable(conn) do
    conn
    |> put_status(:service_unavailable)
    |> put_view(html: CoreWeb.ErrorHTML)
    |> render(:"503")
  end
end
