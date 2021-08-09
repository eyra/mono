defmodule CoreWeb.Lab.PublicTest do
  use CoreWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  alias CoreWeb.Lab.Public

  @expected_message_after_reservation "You have made a reservation"
  setup do
    {:ok,
     lab:
       Factories.insert!(:lab_tool, %{
         time_slots: [
           %{
             location: Faker.Lorem.sentence(),
             start_time: Faker.DateTime.forward(50) |> DateTime.truncate(:second)
           }
         ]
       })}
  end

  describe "show public page" do
    setup [:login_as_member]

    test "show all available time slots", %{conn: conn, lab: lab} do
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Public, lab.id))
      [slot | _] = lab.time_slots
      assert html =~ slot.location
    end

    test "apply for a time slot creates a reservation", %{conn: conn, lab: lab} do
      {:ok, view, html} = live(conn, Routes.live_path(conn, Public, lab.id))
      # The users starts without a reservation
      refute html =~ @expected_message_after_reservation

      # Now let's make the reservation
      html =
        view
        |> element("button", "Apply")
        |> render_click()

      assert html =~ @expected_message_after_reservation

      # The message stays when the page is loaded freshly
      {:ok, _view, html} = live(conn, Routes.live_path(conn, Public, lab.id))
      assert html =~ @expected_message_after_reservation
    end

    test "cancel a reservation removes the reservation info", %{conn: conn, lab: lab} do
      {:ok, view, _html} = live(conn, Routes.live_path(conn, Public, lab.id))

      view
      |> element("button", "Apply")
      |> render_click()

      html =
        view
        |> element("button", "Cancel")
        |> render_click()

      refute html =~ @expected_message_after_reservation
    end
  end
end
