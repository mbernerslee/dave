defmodule Dave.RequestParser do
  alias DaveWeb.RequestStatisticsLive

  @all_time RequestStatisticsLive.all_time()

  def filter(request_statistics, @all_time, _since) do
    request_statistics
  end

  def filter(request_statistics, seconds_ago, since) do
    Enum.map(request_statistics, fn request ->
      %{request | timestamps: filter_timestamps(request.timestamps, seconds_ago, since)}
    end)
  end

  def sort(request_statistics) do
    request_statistics
    |> Enum.sort_by(& &1.http_method, :asc)
    |> Enum.sort_by(& &1.path, :asc)
    |> Enum.sort_by(&length(&1.timestamps), :desc)
  end

  defp filter_timestamps(timestamps, seconds_ago, now) do
    Enum.filter(timestamps, fn timestamp -> filter_timestamp(timestamp, seconds_ago, now) end)
  end

  defp filter_timestamp(nil, _seconds_ago, _now) do
    false
  end

  defp filter_timestamp(timestamp, seconds_ago, now) do
    DateTime.diff(now, timestamp) < seconds_ago
  end
end
