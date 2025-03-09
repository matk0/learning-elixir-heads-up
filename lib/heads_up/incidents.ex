alias HeadsUp.Incidents.Incident
alias HeadsUp.Repo

defmodule HeadsUp.Incidents do
  def list_incidents do
    Repo.all(Incident)
  end

  def get_incident!(id) do
    Repo.get!(Incident, id)
  end

  def urgent_incidents(incident) do
    list_incidents() |> List.delete(incident)
  end
end
