defmodule Dave.IncomingWebRequestHandlerStateBuilder do
  def build do
    %{}
  end

  def add_incident_with_path_and_http_method(state, path, http_method) do
    add_incident_with_path_and_http_method(state, path, http_method, DateTime.utc_now())
  end

  def add_incident_with_path_and_http_method(state, path, http_method, timestamp) do
    Map.update(
      state,
      %{"http_method" => http_method, "path" => path},
      [timestamp],
      fn timestamps ->
        [timestamp | timestamps]
      end
    )
  end
end
