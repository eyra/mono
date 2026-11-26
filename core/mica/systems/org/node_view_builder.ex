defmodule Systems.Org.NodeViewBuilder do
  use Gettext, backend: MicaWeb.Gettext

  alias MicaWeb.UI.Timestamp
  alias Systems.Account
  alias Systems.Org

  def view_model(node, %{is_admin?: is_admin?} = assigns) do
    changeset = Map.get(assigns, :changeset) || Org.NodeModel.changeset(node, %{})

    %{
      changeset: changeset,
      is_admin?: is_admin?,
      research_institute?: Org.NodeModel.research_institute?(node),
      research_institute_note: research_institute_note(node)
    }
  end

  defp research_institute_note(%{research_institute_at: nil}), do: nil

  defp research_institute_note(%{research_institute_at: at, research_institute_by: by}) do
    dgettext("eyra-org", "research.institute.marked.note",
      name: by_name(by),
      date: at |> DateTime.to_naive() |> Timestamp.apply_timezone() |> Timestamp.humanize()
    )
  end

  defp by_name(%Account.User{} = user), do: Account.User.label(user)
  defp by_name(_), do: dgettext("eyra-org", "research.institute.unknown.user")
end
