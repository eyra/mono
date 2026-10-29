defmodule Systems.Storage.Controller do
  alias CoreWeb.UI.Timestamp

  use CoreWeb,
      {:controller,
       [formats: [:html, :json], layouts: [html: CoreWeb.Layouts], namespace: CoreWeb]}

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
      [
        source: source,
        path: "#{export_name}/#{participant_folder(path)}/#{path}",
        timestamp: timestamp
      ]
    end)
    |> Packmatic.build_stream()
    |> Packmatic.Conn.send_chunked(conn, "#{export_name}.zip")
  end

  def export(conn, _, _) do
    service_unavailable(conn)
  end

  @max_donation_bytes 5_000_000

  # shortcut: only reads files on the local filesystem (S3 lists a URL source and gets 503);
  # read S3 objects too before this leaves the spike.
  def donation(conn, %{"id" => id, "path" => path}) do
    endpoint =
      Storage.Public.get_endpoint!(
        String.to_integer(id),
        Storage.EndpointModel.preload_graph(:down)
      )

    with {:authorized, true} <- {:authorized, authorized?(conn, endpoint)},
         {:found, %{source: {:file, file}, size: size}} <- {:found, find_file(endpoint, path)},
         {:size, true} <- {:size, size <= @max_donation_bytes},
         {:ok, json} <- File.read(file),
         {:ok, donation} <- Storage.DonationView.decode(json) do
      conn
      |> put_view(html: Storage.DonationHTML)
      |> render(:donation, path: path, blocks: Storage.DonationView.blocks(donation))
    else
      {:authorized, false} -> forbidden(conn)
      {:found, nil} -> send_resp(conn, :not_found, "")
      _ -> service_unavailable(conn)
    end
  end

  # Only a path the endpoint lists can be read, so the path never reaches the filesystem.
  defp find_file(endpoint, path) do
    endpoint
    |> Storage.Public.list_files()
    |> Enum.find(fn %{path: file_path} -> file_path == path end)
  end

  # A participant id never has spaces or brackets, so this folder cannot clash with one.
  defp participant_folder(path), do: Storage.Donations.participant(path) || "(no participant)"

  defp authorized?(%{assigns: %{current_user: user}}, %Storage.EndpointModel{} = endpoint),
    do: Core.Authorization.can_access?(user, endpoint, Storage.EndpointContentPage)

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
    |> put_view(html: CoreWeb.ErrorHTML)
    |> render(:"403")
  end

  defp service_unavailable(conn) do
    conn
    |> put_status(:service_unavailable)
    |> put_view(html: CoreWeb.ErrorHTML)
    |> render(:"503")
  end
end
