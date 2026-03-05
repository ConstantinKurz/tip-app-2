import json
import requests

URL = "https://api.fifa.com/api/v3/calendar/matches?language=de&count=500&idSeason=285023"
OUTFILE = "spiele.json"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

def extract_field(obj, default=None):
    return obj if obj is not None else default

def main():
    # 1) Daten abrufen
    resp = requests.get(URL, headers=HEADERS)
    resp.raise_for_status()
    data = resp.json()

    results = data.get("Results", [])

    simple_matches = []

    for m in results:
        home = m.get("Home") or m.get("HomeTeam")
        away = m.get("Away") or m.get("AwayTeam")

        match = {
            "homeTeam": extract_field(home.get("TeamName")[0]["Description"] if home and home.get("TeamName") else None),
            "awayTeam": extract_field(away.get("TeamName")[0]["Description"] if away and away.get("TeamName") else None),
            "dateUTC": m.get("Date"),
            "localDate": m.get("LocalDate"),
            "phase": (
                m.get("StageName")[0]["Description"]
                if m.get("StageName")
                else None
            ),
            "matchStatus": m.get("MatchStatus"),
            "result": {
                "home": m.get("HomeTeamScore") or (home.get("Score") if home else None),
                "away": m.get("AwayTeamScore") or (away.get("Score") if away else None)
            }
        }

        simple_matches.append(match)

    # 2) Ergebnis-json schreiben
    with open(OUTFILE, "w", encoding="utf-8") as f:
        json.dump(simple_matches, f, ensure_ascii=False, indent=2)

    print(f"Fertig! {len(simple_matches)} Spiele gespeichert in {OUTFILE}")

if __name__ == "__main__":
    main()