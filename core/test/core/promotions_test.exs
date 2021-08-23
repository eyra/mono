defmodule Core.PromotionsTest do
  use Core.DataCase, async: true
  import Core.Signals.Test
  alias Core.Factories
  alias Core.Pools.Submissions

  describe "update/1" do
    setup do
      promotion =
        Factories.insert!(:promotion, %{
          study: Factories.insert!(:study),
          plugin: "lab",
          parent_content_node: Factories.insert!(:content_node)
        })

      {:ok, promotion: promotion}
    end

    test "sends accepted signal", %{promotion: promotion} do
      Submissions.update(promotion.submission, %{status: :accepted})
      message = assert_signal_dispatched(:submission_accepted)
      assert message.submission.id == promotion.submission.id
    end

    test "do not send accepted signal when the publication date is not set", %{
      promotion: promotion
    } do
      Submissions.update(promotion.submission, %{status: :retacted})
      refute_signal_dispatched(:submission_accepted)
    end
  end
end
