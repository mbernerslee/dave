defmodule Dave.IncomingWebRequestIncidentBuilder do
  alias Dave.Builder

  def build do
    %{}
  end

  def with_incoming_web_request_id(incident, incoming_web_request_id) do
    Map.put(incident, :incoming_web_request_id, incoming_web_request_id)
  end

  def insert(incident, opts \\ []) do
    Builder.insert(incident, "incoming_web_request_incidents", opts)
  end
end
