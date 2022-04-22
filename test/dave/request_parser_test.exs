defmodule Dave.RequestParserTest do
  use ExUnit.Case, async: true
  alias Dave.{Constants, RequestParser, RequestStatisticsBuilder}
  alias DaveWeb.RequestStatisticsLive

  @get Constants.http_method_get()
  @post Constants.http_method_post()

  @all_time RequestStatisticsLive.all_time()

  describe "sort/1" do
    test "sorts by timestamp count, then path, then http_method" do
      timestamp = DateTime.utc_now()

      request_1 =
        RequestStatisticsBuilder.build_request()
        |> RequestStatisticsBuilder.add_timestamp(timestamp)

      request_2_a_a =
        RequestStatisticsBuilder.build_request()
        |> RequestStatisticsBuilder.with_path("a_path")
        |> RequestStatisticsBuilder.with_http_method(@get)
        |> RequestStatisticsBuilder.add_timestamp(timestamp)
        |> RequestStatisticsBuilder.add_timestamp(timestamp)

      request_2_b =
        RequestStatisticsBuilder.build_request()
        |> RequestStatisticsBuilder.with_path("b_path")
        |> RequestStatisticsBuilder.add_timestamp(timestamp)
        |> RequestStatisticsBuilder.add_timestamp(timestamp)

      request_2_a_b =
        RequestStatisticsBuilder.build_request()
        |> RequestStatisticsBuilder.with_path("a_path")
        |> RequestStatisticsBuilder.with_http_method(@post)
        |> RequestStatisticsBuilder.add_timestamp(timestamp)
        |> RequestStatisticsBuilder.add_timestamp(timestamp)

      request_3 =
        RequestStatisticsBuilder.build_request()
        |> RequestStatisticsBuilder.add_timestamp(timestamp)
        |> RequestStatisticsBuilder.add_timestamp(timestamp)
        |> RequestStatisticsBuilder.add_timestamp(timestamp)

      request_4 =
        RequestStatisticsBuilder.build_request()
        |> RequestStatisticsBuilder.add_timestamp(timestamp)
        |> RequestStatisticsBuilder.add_timestamp(timestamp)
        |> RequestStatisticsBuilder.add_timestamp(timestamp)
        |> RequestStatisticsBuilder.add_timestamp(timestamp)

      request_statistics =
        RequestStatisticsBuilder.build_statistics()
        |> RequestStatisticsBuilder.add_request(request_4)
        |> RequestStatisticsBuilder.add_request(request_2_a_a)
        |> RequestStatisticsBuilder.add_request(request_3)
        |> RequestStatisticsBuilder.add_request(request_2_b)
        |> RequestStatisticsBuilder.add_request(request_2_a_b)
        |> RequestStatisticsBuilder.add_request(request_1)

      assert [
               %{timestamps: [_, _, _, _]},
               %{timestamps: [_, _, _]},
               %{timestamps: [_, _], path: "a_path", http_method: @get},
               %{timestamps: [_, _], path: "a_path", http_method: @post},
               %{timestamps: [_, _], path: "b_path"},
               %{timestamps: [_]}
             ] = RequestParser.sort(request_statistics)
    end
  end

  describe "filter/2" do
    test "filters out requests with timestamps more than X seconds since Y timestamp" do
      x_seconds = 10
      y_timestamp = DateTime.utc_now()

      timestamp_a = DateTime.add(y_timestamp, -(x_seconds + 1))
      timestamp_b = DateTime.add(y_timestamp, -(x_seconds - 1))

      request =
        RequestStatisticsBuilder.build_request()
        |> RequestStatisticsBuilder.add_timestamp(timestamp_a)
        |> RequestStatisticsBuilder.add_timestamp(timestamp_b)

      request_statistics =
        RequestStatisticsBuilder.build_statistics()
        |> RequestStatisticsBuilder.add_request(request)

      assert [%{http_method: _, path: _, timestamps: [^timestamp_b]}] =
               RequestParser.filter(request_statistics, x_seconds, y_timestamp)
    end

    test "timestamps of nil are removed for any given filter" do
      x_seconds = 10
      y_timestamp = DateTime.utc_now()

      request =
        RequestStatisticsBuilder.build_request()
        |> RequestStatisticsBuilder.add_timestamp(nil)

      request_statistics =
        RequestStatisticsBuilder.build_statistics()
        |> RequestStatisticsBuilder.add_request(request)

      assert [%{http_method: _, path: _, timestamps: []}] =
               RequestParser.filter(request_statistics, x_seconds, y_timestamp)
    end

    test "the 'all-time' filters nothing away, including timestamps of nil" do
      x_seconds = 10
      y_timestamp = DateTime.utc_now()

      timestamp_a = DateTime.add(y_timestamp, -(x_seconds + 1))
      timestamp_b = DateTime.add(y_timestamp, -(x_seconds - 1))

      request =
        RequestStatisticsBuilder.build_request()
        |> RequestStatisticsBuilder.add_timestamp(timestamp_a)
        |> RequestStatisticsBuilder.add_timestamp(timestamp_b)
        |> RequestStatisticsBuilder.add_timestamp(nil)

      request_statistics =
        RequestStatisticsBuilder.build_statistics()
        |> RequestStatisticsBuilder.add_request(request)

      assert [%{http_method: _, path: _, timestamps: [nil, ^timestamp_b, ^timestamp_a]}] =
               RequestParser.filter(request_statistics, @all_time, y_timestamp)
    end

    test "can filter when there's more than one request in the list" do
      x_seconds = 10
      y_timestamp = DateTime.utc_now()

      timestamp_a = DateTime.add(y_timestamp, -(x_seconds + 1))
      timestamp_b = DateTime.add(y_timestamp, -(x_seconds - 1))

      request_a =
        RequestStatisticsBuilder.build_request()
        |> RequestStatisticsBuilder.add_timestamp(timestamp_a)
        |> RequestStatisticsBuilder.add_timestamp(timestamp_b)
        |> RequestStatisticsBuilder.add_timestamp(nil)

      request_b =
        RequestStatisticsBuilder.build_request()
        |> RequestStatisticsBuilder.add_timestamp(timestamp_a)
        |> RequestStatisticsBuilder.add_timestamp(timestamp_b)
        |> RequestStatisticsBuilder.add_timestamp(nil)

      request_statistics =
        RequestStatisticsBuilder.build_statistics()
        |> RequestStatisticsBuilder.add_request(request_b)
        |> RequestStatisticsBuilder.add_request(request_a)

      assert [
               %{http_method: _, path: _, timestamps: [^timestamp_b]},
               %{http_method: _, path: _, timestamps: [^timestamp_b]}
             ] = RequestParser.filter(request_statistics, x_seconds, y_timestamp)
    end
  end
end
