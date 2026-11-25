# onlyoffice-documentserver-unlimited

Unofficial OnlyOffice DocumentServer image with **Mobile Edit enabled**,
based on the official image.

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

The Docker build itself fails if the Mobile Edit patch does not apply, and the
workflow runs an extra check against the pushed image:

```sh
docker run --rm --entrypoint /bin/sh \
  ghcr.io/zetzzzz/onlyoffice-documentserver-unlimited:10.0.0.1 \
  -c 'grep -o "isSupportEditFeature=()=>1" \
  /var/www/onlyoffice/documentserver/web-apps/apps/*/mobile/dist/js/app.js'
```

## Update to a newer upstream version

1. Bump the base tag in `Dockerfile` (`FROM onlyoffice/documentserver:<version>`).
2. Bump `VERSION` in `.github/workflows/build.yml` to the same version.
3. Push to `main` — the workflow builds and publishes the new tags.

## Notes

- Unofficial build, not affiliated with ONLYOFFICE or thomisus.
- DocumentServer itself is licensed AGPL-3.0; this repository only adds a
  small Dockerfile, workflow and README on top of the official image.
- AI Tools (new in 10.0) are not included in the open-source build; they are
  installed separately upstream.
