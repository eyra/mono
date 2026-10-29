defmodule Next.Config.DevConfigTest do
  # Sets environment variables while config/config.exs is evaluated for dev.
  use ExUnit.Case, async: false

  @vars ~w(HTTP_PORT OPEN_SENT_EMAILS APP_DOMAIN)

  setup do
    saved = Map.new(@vars, &{&1, System.get_env(&1)})
    Enum.each(@vars, &System.delete_env/1)

    on_exit(fn ->
      Enum.each(saved, fn
        {name, nil} -> System.delete_env(name)
        {name, value} -> System.put_env(name, value)
      end)
    end)
  end

  defp dev_config(env) do
    System.put_env(env)
    Config.Reader.read!("config/config.exs", env: :dev)[:core]
  end

  defp port(config), do: config[CoreWeb.Endpoint][:http][:port]
  defp redirect_uri(config), do: config[Systems.Account.Auth.Google][:redirect_uri]
  defp open_url(config), do: config[Systems.Email.Mailer][:open_email_in_browser_url]

  test "without HTTP_PORT the server runs on 4000 and opens sent emails there" do
    config = dev_config(%{})

    assert port(config) == 4000
    assert config[:base_url] == "http://localhost:4000"
    assert redirect_uri(config) == "http://localhost:4000/auth/google/callback"
    assert open_url(config) == "http://localhost:4000/sent_emails"
  end

  test "HTTP_PORT moves the port, links, Google redirect and sent-email viewer" do
    config = dev_config(%{"HTTP_PORT" => "4035"})

    assert port(config) == 4035
    assert config[:base_url] == "http://localhost:4035"
    assert redirect_uri(config) == "http://localhost:4035/auth/google/callback"
    assert open_url(config) == "http://localhost:4035/sent_emails"
  end

  test "APP_DOMAIN still sets the address used in links" do
    config = dev_config(%{"HTTP_PORT" => "4035", "APP_DOMAIN" => "https://example.test"})

    assert port(config) == 4035
    assert config[:base_url] == "https://example.test"
  end

  test "OPEN_SENT_EMAILS=false keeps sent emails in the mailbox only" do
    config = dev_config(%{"HTTP_PORT" => "4035", "OPEN_SENT_EMAILS" => "false"})

    refute Keyword.has_key?(config[Systems.Email.Mailer], :open_email_in_browser_url)
    assert config[Systems.Email.Mailer][:adapter] == Bamboo.LocalAdapter
  end
end
