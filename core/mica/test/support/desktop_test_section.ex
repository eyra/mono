defmodule Systems.Desktop.TestSection do
  @moduledoc """
  A Desktop section for tests. It shows the message in
  `config :mica, Systems.Desktop.TestSection, message: ...`, and hides when no
  message is set. `Systems.Desktop.TestSection.Switch` refreshes it.
  """
  use Systems.Desktop.Section

  @impl true
  def id, do: :test

  @impl true
  def title, do: "Test section"

  @impl true
  def view_model(_user, _assigns) do
    case Mica.Env.get(__MODULE__, []) |> Keyword.get(:message) do
      nil -> nil
      message -> %{message: message}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <p data-testid="desktop-test-section-message"><%= @vm.message %></p>
    """
  end

  defmodule Switch do
    @moduledoc "Refreshes the Desktop of the user whose test section message changed."
    use Frameworks.Concept.Switch

    @impl true
    def intercept({:desktop_test_section, :updated}, %{user: user, from_pid: from_pid}) do
      update_routed(Systems.Desktop.Page, user, from_pid)
      :ok
    end
  end
end
