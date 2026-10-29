defmodule Next.Account.NativeApp do
  @moduledoc """
  Recognises requests from the Next native apps by their
  `NextApp/<version> iOS|Android` user-agent suffix.
  """

  @user_agent ~r/(?:^|\s)NextApp\/[^\s]+\s+(?:iOS|Android)(?:\s|$)/

  def request?(%Plug.Conn{} = conn) do
    conn
    |> Plug.Conn.get_req_header("user-agent")
    |> Enum.any?(&Regex.match?(@user_agent, &1))
  end
end
