# Comparadevis

**Live demo:** https://comparadevis.sliplane.app/

Upload 2-5 contractor quotes (PDFs, in any language) for the same job and get a
side-by-side comparison: a table of line items, the discrepancies between
the quotes, and a reasoned recommendation. Built for syndics and
co-ownership councils.

An agent (Claude) reads the PDFs, records line items and discrepancies
through tool calls, then writes the recommendation once the comparison is
complete.

## Case study

Syndics and co-ownership councils often have to compare several contractor quotes (devis) for the same job, but the quotes arrive as PDFs, often in different languages, that each lay out their prices differently, so comparing them by hand is slow and easy to get wrong. Comparadevis has Claude read the PDFs and record each line item and each disagreement between quotes through tool calls, and it only writes the recommendation once that comparison is complete. A small, fast model (Haiku) does the reading and extraction, and a stronger one (Sonnet) writes the recommendation from the finished table. The hardest part was that quotes often price the same thing on different bases, such as per half hour versus per hour, or monthly versus annual, so a naive table put figures side by side that could not fairly be compared. The fix was to make the agent convert every value in a row to one common unit, show the original in brackets, and flag the mismatch as a discrepancy. The other awkward constraint is that the app has no database: progress lives in the server's memory cache and the page checks it every 2 seconds, which only works if the app runs as a single container with a single web worker.

## Stack

- Ruby 3.3.5, Rails 8.1
- Hotwire (Turbo + Stimulus), Tailwind CSS
- [Anthropic API](https://www.anthropic.com) — Claude Haiku for extraction, Claude Sonnet for the recommendation
- Prawn for the PDF export
- No database — see [Architecture](#architecture) below

## Setup

1. Install Ruby 3.3.5 (see `.ruby-version`).
2. `bundle install`
3. Get `config/master.key` from whoever manages the project's secrets and
   place it at that path. It decrypts `config/credentials.yml.enc` and is
   never committed.
4. Create a `.env` file with an Anthropic API key:
   ```
   ANTHROPIC_API_KEY=sk-ant-...
   ```
   Get one from the [Anthropic Console](https://console.anthropic.com).
5. `bin/dev` — starts the Rails server and the Tailwind watcher together
   (see `Procfile.dev`). The app runs at http://localhost:3000.

## Environment variables

| Variable | Required | Purpose |
|---|---|---|
| `ANTHROPIC_API_KEY` | Always | Used by `ComparisonJob` to call the Anthropic API. |
| `RAILS_MASTER_KEY` | Everywhere except a checkout that already has `config/master.key` | Decrypts `config/credentials.yml.enc`. |

## Running tests

- `bin/rails test` — unit/controller tests
- `bin/rails test:system` — system tests
- `bin/rubocop` — style
- `bin/brakeman` — static security analysis
- `bin/bundler-audit` — gem vulnerability scan
- `bin/importmap audit` — JS dependency vulnerability scan

CI (`.github/workflows/ci.yml`) runs all of these on every pull request.

## Architecture

There is no database. A `Comparison` is built up in memory as
`ComparisonJob` runs, and written to `Rails.cache` after every step; the
panel polls `GET /comparisons/:id` every 2 seconds and re-renders from
whatever is cached, until the job reports `done` or `failed`. Comparisons
expire from the cache after 1 hour.

Because state lives in that in-memory cache, **the app must run as a
single container with a single Puma worker**
(`WEB_CONCURRENCY` unset, so it defaults to 1) — a comparison started on
one process is invisible to another, so multiple replicas or workers would
break polling.

Other things worth knowing:

- Rate limited to 3 comparisons per day per IP
  (`ComparisonsController::MAX_COMPARISONS_PER_DAY`).
- The UI supports English, French, and Dutch via I18n; the uploaded quotes
  can be PDFs in any language.

## Deployment

Deployed as a Docker container — see `Dockerfile` (multi-stage build,
non-root user, Thruster in front of Puma on port 80). Currently hosted on
[Sliplane](https://sliplane.io). Any Docker host works, as long as it
honors the single-instance/single-worker constraint above.

Required environment variables on the host: `ANTHROPIC_API_KEY` and
`RAILS_MASTER_KEY` (copy the value from your local `config/master.key`).

Kamal (`config/deploy.yml`) is included as an alternative deploy path but
still has the placeholder server IP and local registry from the Rails
template — it isn't configured for a real target.
