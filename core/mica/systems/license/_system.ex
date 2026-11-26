defmodule Systems.License.System do
  use Mica.System

  def notifiers, do: [Systems.License.Notify]

  # Daily at 23:05 UTC: just after midnight in Amsterdam, where end dates are
  # counted, in winter (00:05) and summer time (01:05).
  def oban_crons, do: [license_reminder: {"5 23 * * *", Systems.License.ReminderWorker}]
end
