# onlyoffice-documentserver-unlimited

Unofficial OnlyOffice DocumentServer image with **Mobile Edit enabled** and
the **AI Tools plugin** pre-installed, based on the official image.

## Why

The thomisus "unlimited" fork (`ghcr.io/thomisus/onlyoffice-documentserver-unlimited`)
is stuck at 9.2.1: its `.deb` releases stopped there, so its Dockerfile cannot be
bumped to newer versions. Meanwhile the official 9.4+ builds already removed the
20-connection limit, so the only remaining feature of the "unlimited" fork is
Mobile Edit — the mobile web editors ship with editing disabled
(`EditorUIController.isSupportEditFeature = () => false`).

This image is a thin layer on top of the official image: it flips that flag to
`true` in the mobile editors and changes nothing else.

## Image

- `ghcr.io/zetzzzz/onlyoffice-documentserver-unlimited:10.0.0.1`
- `ghcr.io/zetzzzz/onlyoffice-documentserver-unlimited:latest` (currently 10.0.0.1)

Built automatically by GitHub Actions on every push to `main`.

## AI Tools

The 10.0 open-source image ships without AI Tools, and the Plugin Manager
catalog does not list the plugin, so this image bakes in the official AI
plugin **v3.2.2** (`ONLYOFFICE/onlyoffice.github.io`,
`sdkjs-plugins/content/ai`, AGPL-3.0; GUID
`asc.{9DC93CDB-B576-4F0C-B55E-FCC9C48DD007}`). After deploying, the
**AI Tools** tab appears in every editor and the plugin shows up under
Plugins → Background plugins.

Each user connects their own AI provider: AI Tools tab → Settings →
Add Model → provider **OpenAI Compatible** → base URL + API key → pick a
model. Any OpenAI-compatible endpoint works, including a self-hosted one.
Note the plugin calls the provider from the browser, so the provider's
endpoint must allow the Document Server origin (CORS preflight).

## Use

```yaml
services:
  onlyoffice:
    image: ghcr.io/zetzzzz/onlyoffice-documentserver-unlimited:10.0.0.1
    container_name: onlyoffice
    restart: unless-stopped
    ports:
      - "30134:80"
      - "8543:443"
    volumes:
      - onlyoffice-data:/var/www/onlyoffice/Data
    environment:
      - JWT_ENABLED=true
      - JWT_SECRET=<your-secret>
```

Then point your Nextcloud OnlyOffice app (or any WOPI/Nextcloud integration) at
the server URL, with the same JWT secret.

## Verify

The Docker build itself fails if the Mobile Edit patch does not apply or if
the AI plugin download fails its checksum / GUID check, and the workflow runs
an extra check against the pushed image:

```sh
docker run --rm --entrypoint /bin/sh \
  ghcr.io/zetzzzz/onlyoffice-documentserver-unlimited:10.0.0.1 \
  -c 'grep -o "isSupportEditFeature=()=>1" \
  /var/www/onlyoffice/documentserver/web-apps/apps/*/mobile/dist/js/app.js;
  grep "asc.{9DC93CDB-B576-4F0C-B55E-FCC9C48DD007}" \
  /var/www/onlyoffice/documentserver/sdkjs-plugins/ai/config.json'
```

## Update to a newer upstream version

1. Bump the base tag in `Dockerfile` (`FROM onlyoffice/documentserver:<version>`).
2. Bump `VERSION` in `.github/workflows/build.yml` to the same version.
3. Push to `main` — the workflow builds and publishes the new tags.

## Notes

- Unofficial build, not affiliated with ONLYOFFICE or thomisus.
- DocumentServer itself is licensed AGPL-3.0; this repository only adds a
  small Dockerfile, workflow and README on top of the official image.
