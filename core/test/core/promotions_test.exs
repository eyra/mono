defmodule Core.PromotionsTest do
  use Core.DataCase, async: true
  import Frameworks.Signal.TestHelper
  alias Core.Factories
  alias Core.Pools.Submissions

  describe "update/1" do
    setup do
      promotion =
        Factories.insert!(:promotion, %{
          campaign: Factories.insert!(:campaign),
          plugin: "lab",
          parent_content_node: Factories.insert!(:content_node)
        })

      {:ok, promotion: promotion}
    end

    test "do not send accepted signal when the publication date is not set", %{
      promotion: promotion
    } do
      Submissions.update(promotion.submission, %{status: :retracted})
      refute_signal_dispatched(:submission_accepted)
    end
  end
end
