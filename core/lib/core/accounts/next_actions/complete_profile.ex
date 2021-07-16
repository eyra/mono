defmodule Core.Accounts.NextActions.CompleteProfile do
  alias CoreWeb.Router.Helpers, as: Routes

  def to_view_model(socket, _count, _params) do
    %{
      title: "Complete your profile",
      description: "Fill out the missing fields to complete your profile.",
      cta: "Open profile",
      url: Routes.live_path(socket, CoreWeb.User.Profile)
    }
  end
end
