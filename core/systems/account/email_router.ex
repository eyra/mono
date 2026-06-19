defmodule Systems.Account.EmailRouter do
  @google_mx_regex ~r/\.google\.com\.?$/i

  def route(email) when is_binary(email) do
    domain = domain_from(email)

    cond do
      surfconext_domain?(domain) -> :surfconext
      google_workspace_domain?(domain) -> :google
      true -> :otp
    end
  end

  defp domain_from(email) do
    email |> String.split("@") |> List.last() |> String.downcase()
  end

  defp surfconext_domain?(domain) do
    domain in Application.get_env(:core, :surfconext_domains, [])
  end

  defp google_workspace_domain?(domain) do
    :inet_res.lookup(String.to_charlist(domain), :in, :mx)
    |> Enum.any?(fn {_prio, host} -> Regex.match?(@google_mx_regex, to_string(host)) end)
  rescue
    _ -> false
  end
end
