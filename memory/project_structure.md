---
name: Project Structure
description: Pokedex Flutter app + Go API backend location and data flow for Bulbapedia/PokemonDB data
type: project
---

The pokedex Flutter app (`/Users/timmy/workspace/public-projects/pokedex`) has a companion Go API backend at `../pokemon-api` (`/Users/timmy/workspace/public-projects/pokemon-api`).

**Backend (Go, chi router):**
- Routes in `main.go`, handlers in `handlers/`
- DB queries in `db/queries.go`
- Serves biology, held items, game locations scraped from Bulbapedia

**Scrapers (Python/Scrapy) at `pokemon-api/pokemondb_scraper/pokemondb_scraper/spiders/`:**
- `bulbapedia_pokemon_spider.py` — scrapes biology text + wild held items from Bulbapedia
- `bulbapedia_pokemon_locations_spider.py` — scrapes game locations
- `bulbapedia_item_locations_spider.py`, `bulbapedia_tm_locations_spider.py` — items/TMs
- `pokemondb_*.py` — scrape abilities, moves, natures, items, locations from PokemonDB

**Flutter app API calls (all via `PokeApiService.baseUrl = https://poke-api.duocore.dev:158/api/v2`):**
- `/pokemon/{id}/biology` → biology text from Bulbapedia
- `/pokemon/{id}/held-items` → wild held items from Bulbapedia
- `/pokemon/{id}/game-locations` → game locations from Bulbapedia

**Why:** Knowing the backend exists at `../pokemon-api` means API issues or missing data should be investigated there, not just in the Flutter app.
**How to apply:** When debugging missing data or API responses, check the Go handlers and DB queries in `../pokemon-api` first.
