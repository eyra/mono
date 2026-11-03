defmodule Systems.Email.DeliveryTest do
  use Mica.DataCase, async: true
  use Oban.Testing, repo: Mica.Repo
  use Bamboo.Test

  alias Systems.Email

  @args %{
    "to" => ["user@example.com"],
    "from" => "sender@example.com",
    "title" => "Title",
    "byline" => "Byline",
    "message" => "Plain message"
  }

  test "sends a notification with the default subject" do
    assert :ok = perform_job(Email.Delivery, @args)

    assert_delivered_email_matches(%{subject: "Next notification", html_body: html})
    assert html =~ "<p>Plain message</p>"
  end

  test "sends the subject and HTML part it is given" do
    args =
      Map.merge(@args, %{
        "subject" => "Custom subject",
        "html_message" => "<div>Rich <strong>text</strong></div>"
      })

    assert :ok = perform_job(Email.Delivery, args)

    assert_delivered_email_matches(%{
      subject: "Custom subject",
      html_body: html,
      text_body: text
    })

    assert html =~ "<div>Rich <strong>text</strong></div>"
    assert text =~ "Plain message"
  end

  test "a queued email model reaches the delivery with all its fields" do
    email = %Email.Model{
      to: ["one@example.com", "two@example.com"],
      subject: "Custom subject",
      title: "Title",
      byline: "Byline",
      message: "Plain message",
      html_message: "<div>Rich</div>"
    }

    assert {:ok, _job} = Email.Public.deliver_later!(email)
    assert [%{args: args}] = all_enqueued(worker: Email.Dispatcher)
    assert :ok = perform_job(Email.Dispatcher, args)

    assert [%{"to" => ["one@example.com"]} = delivery, %{"to" => ["two@example.com"]}] =
             all_enqueued(worker: Email.Delivery)
             |> Enum.map(& &1.args)
             |> Enum.sort_by(& &1["to"])

    assert %{"subject" => "Custom subject", "html_message" => "<div>Rich</div>"} = delivery
  end
end
