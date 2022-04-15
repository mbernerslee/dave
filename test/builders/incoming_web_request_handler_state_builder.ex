defmodule Dave.IncomingWebRequestHandlerStateBuilder do
  def build do
    %{}
  end

  def add_incident_with_path_and_http_method(state, path, http_method) do
    Map.update(state, %{"http_method" => http_method, "path" => path}, 1, fn count ->
      count + 1
    end)
  end
end
