defmodule Systems.Storage.Controller do
  alias MicaWeb.UI.Timestamp

  use MicaWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: MicaWeb.Layouts], namespace: MicaWeb]}

  alias Frameworks.Concept

  alias Systems.Storage
  alias Systems.Rate

  def export(conn, %{"id" => id}) do
    endpoint =
      Storage.Public.get_endpoint!(
        String.to_integer(id),
        Storage.EndpointModel.preload_graph(:down)
      )

    if authorized?(conn, endpoint) do
      special = Storage.EndpointModel.special(endpoint)
      export(conn, special, branch_name(conn, id))
    else
      forbidden(conn)
    end
  end

  def export(
        %{remote_ip: remote_ip} = conn,
        %Storage.BuiltIn.EndpointModel{} = builtin,
        branch_name
      ) do
    date = Timestamp.now() |> Timestamp.format_date_short!()

    export_name =
      [date, branch_name]
      |> Enum.join(" ")
      |> Slug.slugify(separator: ?_)

    builtin
    |> Storage.BuiltIn.Backend.list_files()
    |> request_permission(remote_ip)
    |> Enum.map(fn %{source: source, path: path, timestamp: timestamp} ->
      [source: source, path: "#{export_name}/#{path}", timestamp: timestamp]
    end)
    |> Packmatic.build_stream()
    |> Packmatic.Conn.send_chunked(conn, "#{export_name}.zip")
  end

  def export(conn, _, _) do
    service_unavailable(conn)
  end

  defp authorized?(%{assigns: %{current_user: user}}, %Storage.EndpointModel{} = endpoint),
    do: Mica.Authorization.can_access?(user, endpoint, Storage.EndpointContentPage)

  defp branch_name(%{assigns: %{branch: branch}}, _id) when not is_nil(branch),
    do: Concept.Branch.name(branch, :parent)

  defp branch_name(_conn, id), do: "endpoint_#{id}"

  defp request_permission(files, remote_ip) when is_list(files) do
    size = Enum.reduce(files, 0, fn %{size: size}, acc -> acc + size end)
    remote_ip = to_string(:inet_parse.ntoa(remote_ip))
    # raises error when request is denied
    Rate.Public.request_permission(:storage_export, remote_ip, size)
    files
  end

  defp forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> put_view(html: MicaWeb.ErrorHTML)
    |> render(:"403")
  end

  defp service_unavailable(conn) do
    conn
    |> put_status(:service_unavailable)
    |> put_view(html: MicaWeb.ErrorHTML)
    |> render(:"503")
  end
end
