[
  # https://github.com/phoenixframework/phoenix/issues/5437
  {"systems/benchmark/export_controller.ex", :no_return},
  {"systems/benchmark/export_controller.ex", :call},
  # issue with HTTPPoison not supporting HTTP method :mkcol
  {"systems/storage/yoda/client.ex", :no_return},
  {"systems/storage/yoda/client.ex", :call}
]
