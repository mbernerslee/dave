defmodule Dave.Support.DateTimeUtils do
  @day_in_seconds 86_400
  @hour_in_seconds 3_600
  @minute_in_seconds 60

  def within_a_second?(datetime_a, datetime_b) do
    diff = DateTime.diff(datetime_a, datetime_b, :microsecond)
    modulus(diff) < 1_000_000
  end

  def time_ago(:days, days) do
    DateTime.add(DateTime.utc_now(), -@day_in_seconds * days)
  end

  def time_ago(:hours, hours) do
    DateTime.add(DateTime.utc_now(), -@hour_in_seconds * hours)
  end

  def time_ago(:miniutes, miniutes) do
    DateTime.add(DateTime.utc_now(), -@minute_in_seconds * miniutes)
  end

  defp modulus(diff) do
    if diff > 0 do
      diff
    else
      -diff
    end
  end
end
