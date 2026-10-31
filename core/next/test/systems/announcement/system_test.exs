defmodule Systems.Announcement.SystemTest do
  use ExUnit.Case, async: true

  test "Next lists the announcement system" do
    assert Systems.Announcement.System in Next.SaaS.systems()
  end

  test "declares the announcements flag, off by default in Next" do
    assert Systems.Announcement.System.feature_flags() == [:announcements]
    assert Next.SaaS.feature_flags()[:announcements] == false
  end
end
