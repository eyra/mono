[
  # https://github.com/phoenixframework/phoenix/issues/5437, fixed in Phoenix 1.7.3 or higher
  {"systems/benchmark/export_controller.ex", :no_return},
  {"systems/benchmark/export_controller.ex", :call},
  # issue with HTTPPoison not supporting HTTP method :mkcol
  {"systems/storage/yoda/client.ex", :no_return},
  {"systems/storage/yoda/client.ex", :call},
  # Deprecated fiunction raises exception
  {"systems/assignment/_director.ex", :no_return},
  {"systems/assignment/_private.ex", :no_return},
  {"systems/campaign/builders/promotion_landing_page.ex", :no_return}
]
