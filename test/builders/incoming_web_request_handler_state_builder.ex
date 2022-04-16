defmodule Dave.IncomingWebRequestHandlerStateBuilder do
  alias Dave.{Constants, IncomingWebRequestBuilder}

  @moduledoc """
  build individual requests wtih build_request, with_path & with_http_method
  then call build() |> add_request(the_request_you_made_with_the_above_functions)
  """

  def build do
    %{}
  end

  def build_request do
    http_method = Enum.random(Constants.http_methods())
    path = IncomingWebRequestBuilder.unique_path()

    {%{"http_method" => http_method, "path" => path}, []}
  end

  def with_path({request, timestamps}, path) do
    {Map.put(request, "path", path), timestamps}
  end

  def with_http_method({request, timestamps}, http_method) do
    {Map.put(request, "http_method", http_method), timestamps}
  end

  def with_incident_timestamp({request, timestamps}, timestamp) do
    {request, [timestamp | timestamps]}
  end

  def add_request(state, {request, timestamps}) do
    Map.put(state, request, timestamps)
  end
end
