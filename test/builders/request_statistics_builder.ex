defmodule Dave.RequestStatisticsBuilder do
  alias Dave.{Constants, IncomingWebRequestBuilder}

  def build_statistics do
    []
  end

  def add_request(statistics, request) do
    [request | statistics]
  end

  def build_request do
    http_method = Enum.random(Constants.http_methods())
    path = IncomingWebRequestBuilder.unique_path()

    %{http_method: http_method, path: path, timestamps: []}
  end

  def with_path(request, path) do
    Map.put(request, :path, path)
  end

  def with_http_method(request, http_method) do
    Map.put(request, :http_method, http_method)
  end

  def add_timestamp(request, timestamp) do
    Map.update!(request, :timestamps, fn timestamps -> [timestamp | timestamps] end)
  end
end
