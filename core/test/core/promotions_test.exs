defmodule Core.PromotionsTest do
  use Core.DataCase, async: true
  import Core.Signals.Test
  alias Core.Factories
  alias Core.Promotions

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

    test "sends published signal", %{promotion: promotion} do
      Promotions.update(promotion, %{published_at: DateTime.now!("Etc/UTC")})
      message = assert_signal_dispatched(:promotion_published)
      assert message.promotion.id == promotion.id
    end

    test "do not send published signal when the publication date is not set", %{
      promotion: promotion
    } do
      Promotions.update(promotion, %{title: "some title"})
      refute_signal_dispatched(:promotion_published)
    end
  end

  describe "create/3" do
    setup do
      {:ok,
       content_node: Factories.insert!(:content_node),
       auth_parent: nil,
       attrs: %{
         title: Faker.Lorem.sentence(),
         study: Factories.insert!(:study),
         plugin: "lab",
         parent_content_node: Factories.insert!(:content_node)
       }}
    end

    test "sends published signal", %{
      content_node: content_node,
      auth_parent: auth_parent,
      attrs: attrs
    } do
      Promotions.create(
        Map.merge(attrs, %{published_at: DateTime.now!("Etc/UTC")}),
        auth_parent,
        content_node
      )

      message = assert_signal_dispatched(:promotion_published)
      assert message.promotion.id
    end

    test "do not send published signal when not yet published", %{
      content_node: content_node,
      auth_parent: auth_parent,
      attrs: attrs
    } do
      Promotions.create(
        attrs,
        auth_parent,
        content_node
      )

      refute_signal_dispatched(:promotion_published)
    end
  end
end
