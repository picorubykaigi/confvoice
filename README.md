# ConfVoice

ConfVoice is a Rails application for collecting conference session feedback from QR codes. Organizers can review submissions in real time and share only moderated feedback with speakers.

This fork is styled for [PicoRubyKaigi 2026 Assemble](https://picorubykaigi.org/). The attendee pages use the event's breadboard-inspired colors, dot lettering, and Ruby artwork. Conference and session data are still managed through the organizer dashboard; the demo seeds are not the official program.

The event images in `public/picorubykaigi-*.png` are by the PicoRubyKaigi 2026 Assemble Team, from the [official goodies](https://picorubykaigi.org/goodies/), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The Conti Neue 2P font comes from the event website. The interface uses the same DotGothic16 body type and Jersey 10 navigation type as the event site. Fonts are served locally from `app/assets/fonts`; the Google Fonts licenses are included alongside them.

## Requirements

- Ruby 4.0.x
- Rails 8.1.x
- PostgreSQL 16+
- libvips 8.13+ for image attachments
- Docker, for the production/Kamal deployment flow

## Setup

Start PostgreSQL and ensure your local database role can create databases, or export a `DATABASE_URL` for your local instance.

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/dev
```

Use `bin/dev` for local development so the Rails server and Tailwind watcher run together. If you run `bin/rails server` directly after cleaning assets, rebuild styles with `bin/rails tailwindcss:build`.

Development and tests do not need the maintainer's `config/master.key`; Rails generates a local secret when no credentials key is available.

The seed data creates:

- Admin: `admin@example.com / confvoice-local-password`
- Organizer: `organizer@example.com / confvoice-local-password`
- Speaker: `speaker@example.com / confvoice-local-password`

These accounts, sessions, and feedback are demonstration data. The sample event and speaker names do not represent an official conference schedule or actual attendee submissions.

Set `CONFVOICE_SEED_PASSWORD` to override the local seed password for newly created accounts. Re-running seeds does not change existing passwords. Production seeds require both `ALLOW_PRODUCTION_SEEDS=true` for an intentional one-time bootstrap and a nonblank `CONFVOICE_SEED_PASSWORD` different from the documented default. Never expose existing demo accounts with their default password.

## Environment

Use `.env.example` as a reference and export the values in your shell or configure them in your deployment environment. The application does not load `.env` files automatically.

Required in production:

- `DATABASE_URL`
- `RAILS_MASTER_KEY`
- `APP_HOST` (or `RENDER_EXTERNAL_HOSTNAME` on Render)

Common optional settings:

- `MAIL_FROM`
- `SMTP_ADDRESS`
- `SMTP_USERNAME`
- `SMTP_PASSWORD`
- `ACTIVE_STORAGE_SERVICE`
- `RAILS_ASSUME_SSL`
- `RAILS_FORCE_SSL`
- `CONFVOICE_SELF_REGISTRATION_ENABLED`
- `CONFVOICE_OGP_IMAGE_UPLOAD_ENABLED`

## Features

- Conference and session management
- Anonymous feedback submission with duplicate prevention
- Quick reactions
- QR code pages for sessions
- Organizer dashboard with charts, reaction counts, and feedback keywords
- Speaker invite links with a read-only live portal
- CSV export with UTF-8 BOM for Excel
- PDF slide attachment per session
- Japanese interface
- Rack::Attack rate limits
- Solid Queue, Solid Cache, and Solid Cable
- Kamal deployment template

## Tests

```bash
bin/rails test
bin/rails zeitwerk:check
```

## Deployment

Production credentials are stored in `config/credentials/production.yml.enc`. Set `RAILS_MASTER_KEY` to the matching `config/credentials/production.key`, which is ignored by Git and excluded from the Docker image. Keep a private backup of this key. If you do not have it, request it from the deployment owner; generating a different key will not decrypt the existing file.

For a separate, new deployment, generate a new credentials/key pair with `EDITOR=vi bin/rails credentials:edit --environment production` after moving the existing production credentials aside. Keep the generated `secret_key_base` and commit only the encrypted file. Do not replace credentials for an existing deployment without planning a key rotation. Local development does not require a production key.

### Render

This repository includes `render.yaml` for a Docker-based Render Blueprint. It creates:

- One paid Starter Docker web service in Singapore
- One paid Basic 256 MB Render Postgres database with 1 GB storage in Singapore
- `DATABASE_URL`, `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL`, and `CABLE_DATABASE_URL` pointing at the same internal database
- Solid Queue running inside Puma for the single-service deployment

Deploy steps:

1. Push this repository to GitHub/GitLab/Bitbucket.
2. In Render, create a new Blueprint instance from this repository.
3. When prompted for `RAILS_MASTER_KEY`, paste the contents of `config/credentials/production.key`.
4. Review the charges for the web service and database, then deploy.

On Render, the app uses `RENDER_EXTERNAL_HOSTNAME` automatically for host authorization and mailer URLs. If you add a custom domain, set `APP_HOST` to that domain in the web service environment variables.

`CONFVOICE_OGP_IMAGE_UPLOAD_ENABLED` defaults to `false` in production. Keep it disabled until durable Active Storage storage is configured; the service filesystem is ephemeral even on paid plans without a persistent disk. PDF uploads also require durable storage. After configuring it, set the flag to `true` to show the OGP image upload controls.

The Docker entrypoint runs `bin/rails db:prepare` before starting the Rails server, so the initial deploy and later migrations are applied at boot. Automatic seeding is disabled in production to avoid loading demo accounts or failing the first boot on the production seed guard. For higher-traffic production use, move migrations to a Render pre-deploy command instead of running them during boot.

After the first deployment, open the web service's Shell and run `bin/rails console`. Create the first administrator with your email address and a password of at least 12 characters:

```ruby
require "io/console"

User.create!(name: "Administrator", email_address: "your-email@example.com", role: :admin) do |user|
  user.password = IO.console.getpass("Password (at least 12 characters): ")
  user.password_confirmation = user.password
end
```

Sign in at `/session/new` to create the event and talks. Production self-registration is disabled by default, and local demo accounts are not copied to Render.

### Kamal

`config/deploy.yml` is prepared for Kamal 2. Replace the placeholder host, image, registry user, and secrets before running:

```bash
kamal setup
kamal deploy
```

For production email notification, configure SMTP-related environment variables.
