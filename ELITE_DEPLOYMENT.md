# Elite Deployment

Elite serves this Shiny app on the LAN at:

```text
http://elite:3838/
```

The live checkout on Elite is:

```text
/srv/nvme_apps/stacks/vorogazeaoi3
```

That checkout tracks GitHub `main` using Elite's read-only deploy key via the
SSH alias `github.com-vorogazeaoi3`.

## Update Elite After Pushing To GitHub

Use this from another machine, after your local changes have been committed and
pushed to GitHub. It pulls the latest `main`, rebuilds the Docker image if
needed, and restarts the Shiny container.

```bash
ssh elite 'cd /srv/nvme_apps/stacks/vorogazeaoi3 && git pull --ff-only && docker compose up -d --build'
```

The `--ff-only` flag keeps Elite as a deployment checkout. If Git refuses to
fast-forward, inspect the state rather than making merge commits on Elite.

## Check The Running App

Use this after an update to confirm Docker thinks the container is running and
to show the latest app logs.

```bash
ssh elite 'cd /srv/nvme_apps/stacks/vorogazeaoi3 && docker compose ps && docker logs --tail=80 vorogazeaoi3'
```

If the container has just restarted, health may say `starting` for a few
seconds. Re-run the check after a short pause.

## Check The HTTP Endpoint

Use this from a LAN machine to confirm the Shiny endpoint is responding.

```bash
curl -I http://elite:3838/
```

## Show The Deployed Commit

Use this to see exactly which commit Elite is serving.

```bash
ssh elite 'cd /srv/nvme_apps/stacks/vorogazeaoi3 && git status --short && git rev-parse --short HEAD'
```

`git status --short` should normally print nothing on Elite. The commit hash
should match the GitHub `main` commit you meant to deploy.

## Follow Logs During Startup

Use this if the app is starting slowly or you want to watch Shiny output live.

```bash
ssh elite 'cd /srv/nvme_apps/stacks/vorogazeaoi3 && docker compose logs -f --tail=100 vorogazeaoi3'
```

Press `Ctrl-C` to stop following logs. This does not stop the container.

## If Already SSHed Into Elite

Use this shorter form only when your shell is already logged into Elite.

```bash
cd /srv/nvme_apps/stacks/vorogazeaoi3 && git pull --ff-only && docker compose up -d --build
```
