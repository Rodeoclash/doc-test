# Open an interactive shell in a container
shell service="backend":
    docker compose run -it --rm {{service}} sh

# Run a command in a container (e.g. just run backend mix test)
run service +cmd:
    docker compose run --rm {{service}} {{cmd}}

# Connect an IEx console to the running Phoenix server
console:
    docker compose exec backend iex --sname console --cookie dev --remsh backend

# Start all services
start:
    docker compose up

# Run all lint checks
lint: lint-js lint-elixir

# Lint and format JS/TS files with Biome
lint-js:
    npx @biomejs/biome check --write backend/assets/js/

# Compile-check Elixir with warnings as errors
lint-elixir:
    docker compose run --rm backend mix compile --warnings-as-errors

# Drop, create, migrate, and seed the database
reset-db:
    docker compose run --rm backend sh -c "mix ecto.drop && mix ecto.setup"
