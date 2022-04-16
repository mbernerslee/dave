defmodule Dave.IncomingWebRequestIncidentBuilder do
  alias Dave.Builder

  def build do
    %{}
  end

  def with_incoming_web_request_id(incident, incoming_web_request_id) do
    Map.put(incident, :incoming_web_request_id, incoming_web_request_id)
  end

  def without_timestamps(incoming_web_request) do
    incoming_web_request
    |> with_timestamps(nil)
    |> historical()
  end

  def with_timestamps(incoming_web_request, timestamp) do
    Map.merge(incoming_web_request, %{inserted_at: timestamp, updated_at: timestamp})
  end

  def historical(incoming_web_request) do
    Map.put(incoming_web_request, :historical, true)
  end

  def insert(incident, opts \\ []) do
    Builder.insert(incident, "incoming_web_request_incidents", opts)
  end
end
