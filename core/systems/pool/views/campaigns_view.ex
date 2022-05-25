defmodule Systems.Pool.CampaignsView do
  use CoreWeb.UI.LiveComponent

  alias Systems.{
    NextAction
  }

  alias Core.Accounts

  alias CoreWeb.UI.ContentList

  alias Frameworks.Pixel.Text.{Title2}

  prop(props, :map, required: true)

  data(submitted, :list)
  data(accepted, :list)

  def update(
        %{props: %{campaigns: %{submitted: submitted, accepted: accepted}}} = _params,
        socket
      ) do
    clear_review_submission_next_action()

    {
      :ok,
      socket
      |> assign(submitted: submitted)
      |> assign(accepted: accepted)
    }
  end

  defp clear_review_submission_next_action do
    for user <- Accounts.list_pool_admins() do
      NextAction.Context.clear_next_action(user, Core.Pools.ReviewSubmission)
    end
  end

  def render(assigns) do
    ~F"""
      <ContentArea>
        <MarginY id={:page_top} />
        <Case value={Enum.count(@submitted) + Enum.count(@accepted) > 0} >
          <True>
            <Title2>
              {dgettext("link-studentpool", "submitted.title")}
              <span class="text-primary"> {Enum.count(@submitted)}</span>
            </Title2>
            <ContentList items={@submitted} />
            <Spacing value="XL" />
            <Title2>
              {dgettext("link-studentpool", "accepted.title")}
              <span class="text-primary"> {Enum.count(@accepted)}</span>
            </Title2>
            <ContentList items={@accepted} />
          </True>
          <False>
            <Empty
              title={dgettext("link-studentpool", "campaigns.empty.title")}
              body={dgettext("link-studentpool", "campaigns.empty.description")}
              illustration="items"
            />
          </False>
        </Case>
      </ContentArea>
    """
  end
end
