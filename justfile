# Open an interactive shell in a container
shell service="backend":
    docker compose run -it --rm {{service}} sh

# Run a command in a container (e.g. just run backend mix test)
run service +cmd:
    docker compose run --rm {{service}} {{cmd}}

# Connect an IEx console to the running Phoenix server
console:
    docker compose exec backend iex --sname console --cookie dev --remsh backend
