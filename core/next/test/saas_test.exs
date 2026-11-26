defmodule Next.SaaSTest do
  # Next's composition. Mica's own collection rules are tested in
  # mica/test/mica/saas_test.exs, on a composition of Mica's systems.
  use ExUnit.Case, async: true

  test "the configured SaaS lists Mica's systems first" do
    assert Mica.SaaS.module() == Next.SaaS
    assert List.starts_with?(Mica.SaaS.systems(), Mica.Systems.all())
    assert Mica.SaaS.checked_systems(Next.SaaS) == Next.SaaS.systems()
  end

  test "signal handlers are collected from all systems, sorted by module name within the systems" do
    handlers = Mica.SaaS.signal_handlers()

    assert handlers ==
             Enum.sort_by(handlers, &String.replace(inspect(&1), ~r/^\w+\.(?=Systems\.)/, ""))

    assert Systems.Assignment.Switch in handlers
    assert Next.Systems.Zircon.Switch in handlers
  end

  test "Next declares every flag it sets, and nothing more" do
    assert Keyword.keys(Mica.SaaS.feature_flags()) ==
             Enum.sort(Keyword.keys(Next.SaaS.feature_flags()))
  end

  test "the systems declare their queues and quotas" do
    assert Mica.SaaS.oban_queues() == [
             affiliate_callback: 10,
             email_dispatchers: 1,
             email_delivery: 1,
             ris_import: 1
           ]

    assert Keyword.keys(Mica.SaaS.oban_crons()) == [
             :advert_expiration,
             :pay_in_expiration,
             :auto_approve,
             :data_donation_cleanup,
             :license_reminder,
             :payment_reconciliation,
             :auth_code_cleanup
           ]

    assert [service: :signup, limit: 5, unit: :call, window: :minute, scope: :local] in Mica.SaaS.rate_quotas()
  end
end
