defmodule Systems.Promotion.Test do
  use Core.DataCase, async: true
  import Frameworks.Signal.TestHelper
  alias Core.Factories

  alias Systems.{
    Pool
  }

  describe "update/1" do
    setup do
      promotion = Factories.insert!(:promotion)
      submission = Factories.insert!(:submission)
      {:ok, promotion: promotion, submission: submission}
    end

    test "do not send accepted signal when the publication date is not set", %{
      submission: submission
    } do
      Pool.Public.update(submission, %{status: :retracted})
      refute_signal_dispatched(:submission_accepted)
    end
  end
end
