alias HeadsUp.Incidents.Incident
alias HeadsUp.Repo

import Ecto.Query

defmodule HeadsUp.Incidents do
  def list_incidents do
    Repo.all(Incident)
  end

  def filter_incidents do
    Incident
    |> where([i], ilike(i.name, "%in%"))
    |> order_by(desc: :name)
    |> Repo.all()
  end

  def get_incident!(id) do
    Repo.get!(Incident, id)
  end

  def urgent_incidents(incident) do
    Incident
    |> where([i], i.id != ^incident.id)
    |> order_by(:priority)
    |> limit(3)
    |> Repo.all()
  end
end
