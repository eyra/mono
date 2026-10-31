defmodule Systems.Announcement.Presenter do
  @behaviour Frameworks.Concept.Presenter

  alias Systems.Announcement

  @impl true
  def view_model(Announcement.AdminView, model, assigns) do
    Announcement.AdminViewBuilder.view_model(model, assigns)
  end
end
