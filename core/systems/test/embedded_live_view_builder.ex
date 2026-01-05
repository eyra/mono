defmodule Systems.Test.EmbeddedLiveViewBuilder do
  alias Systems.Test

  def view_model(
        %Test.EmbeddedModel{
          id: id,
          title: title,
          items: items
        },
        _assigns
      ) do
    %{
      id: id,
      title: title,
      items: items || [1, 2, 3]
    }
  end
end
