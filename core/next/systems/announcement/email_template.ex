defmodule Next.Systems.Announcement.EmailTemplate do
  @moduledoc """
  The email of a high-priority announcement, readable on its own: the title,
  the summary, the full body and a link to the announcement page. The HTML
  part has the cleaned body (`Frameworks.Pixel.RichText.clean_stored/1`); the
  plain-text part has the text of the body.

  The link is the plain page address. Opening the email or following the link
  changes nothing in Next; only opening the page marks the announcement read.
  """
  use Phoenix.Component
  use Gettext, backend: MicaWeb.Gettext

  alias Frameworks.Pixel.RichText
  alias Next.Systems.Announcement
  alias Systems.Email

  embed_templates("email_template/*.html", suffix: "_html")
  embed_templates("email_template/*.text", suffix: "_text")

  @blocks ~w(div p h1 h2 h3 h4 h5 h6 blockquote pre ul ol figure figcaption)

  @doc "The email of `announcement`, without recipients, rendered in the current locale."
  def email(%Announcement.Model{id: id, title: title, summary: summary, body: body}) do
    url = Announcement.Private.page_url(id)
    body = RichText.clean_stored(body)

    %Email.Model{
      to: [],
      subject: title,
      title: title,
      byline: summary,
      message: announcement_text(%{body: to_text(body), url: url}) |> to_binary(),
      html_message: announcement_html(%{body: body, url: url}) |> to_binary()
    }
  end

  defp to_binary({:safe, _} = safe), do: Phoenix.HTML.safe_to_string(safe)
  defp to_binary(binary) when is_binary(binary), do: binary

  @doc """
  The text of rich-text HTML, with blocks and line breaks as new lines, list
  items as "- " lines and links followed by their address.
  """
  def to_text(html) when is_binary(html) do
    case Floki.parse_fragment(html) do
      {:ok, tree} -> tree |> Enum.map_join(&text/1) |> tidy()
      {:error, _} -> html
    end
  end

  defp text(text) when is_binary(text), do: text
  defp text({"br", _, _}), do: "\n"
  defp text({"li", _, children}), do: "\n- " <> Enum.map_join(children, &text/1)
  defp text({"a", attrs, children}), do: link_text(Enum.map_join(children, &text/1), attrs)

  defp text({tag, _, children}) when tag in @blocks,
    do: "\n\n" <> Enum.map_join(children, &text/1) <> "\n\n"

  defp text({_tag, _, children}), do: Enum.map_join(children, &text/1)
  defp text(_comment), do: ""

  defp link_text(label, attrs) do
    case List.keyfind(attrs, "href", 0) do
      {"href", href} when href not in ["", label] -> "#{label} (#{href})"
      _ -> label
    end
  end

  defp tidy(text) do
    text
    |> String.split("\n")
    |> Enum.map_join("\n", &String.trim/1)
    |> String.replace(~r/\n{3,}/, "\n\n")
    |> String.trim()
  end
end
