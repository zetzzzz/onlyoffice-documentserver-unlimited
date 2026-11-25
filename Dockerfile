# OnlyOffice DocumentServer 10.0.0.1 with Mobile Edit enabled + AI Tools plugin.
# Unofficial build: a thin layer on top of the official image.
#
# Why this exists:
# - The thomisus "unlimited" fork (ghcr.io/thomisus/onlyoffice-documentserver-unlimited)
#   is stuck at 9.2.1: its .deb releases stopped there, so its Dockerfile
#   cannot be bumped to newer versions.
# - The official 9.4+ builds already removed the 20-connection limit,
#   so the only remaining feature of the "unlimited" fork is Mobile Edit.
# - This image takes the official 10.0.0.1 image, flips the Mobile Edit
#   flag in the mobile web-apps, and bakes in the AI Tools plugin
#   (which the 10.0 open-source image ships without, and which the
#   Plugin Manager catalog does not list).
#
# The build FAILS if a patch does not apply or a checksum does not match,
# so a silent no-op (e.g. upstream renamed the flag, or the plugin
# download changed) can never ship.
FROM onlyoffice/documentserver:10.0.0.1

# Mobile editors ship with EditorUIController.isSupportEditFeature = () => false,
# which disables editing from mobile browsers. Flip it to true.
# Covers document, spreadsheet, presentation and visio editors
# (whatever is present under apps/*/mobile).
RUN set -eux; \
    patched=0; \
    for f in /var/www/onlyoffice/documentserver/web-apps/apps/*/mobile/dist/js/app.js; do \
        [ -f "$f" ] || continue; \
        sed -i \
            -e 's/isSupportEditFeature=()=>!1/isSupportEditFeature=()=>1/g' \
            -e 's/isSupportEditFeature=()=>{return!1}/isSupportEditFeature=()=>{return 1}/g' \
            -e 's/isSupportEditFeature=function(){return!1}/isSupportEditFeature=function(){return 1}/g' \
            "$f"; \
        if grep -qE 'isSupportEditFeature=\(\)=>(1|\{return 1\})|isSupportEditFeature=function\(\)\{return 1\}' "$f"; then \
            echo "patched: $f"; patched=$((patched+1)); \
        else \
            echo "ERROR: Mobile Edit patch did not apply to $f" >&2; exit 1; \
        fi; \
    done; \
    [ "$patched" -ge 3 ] || { echo "ERROR: only $patched mobile editor(s) patched, expected at least 3" >&2; exit 1; }; \
    echo "Mobile Edit enabled in $patched editor(s)"

# AI Tools plugin v3.2.2 (official plugin, ONLYOFFICE/onlyoffice.github.io,
# sdkjs-plugins/content/ai, AGPL-3.0). The 10.0 open-source image ships
# without it and the Plugin Manager catalog does not list it, so it is
# installed here into sdkjs-plugins/, where DocumentServer picks up
# bundled plugins for all users.
# Verified 2026-11-25: ai.plugin, 2,205,374 bytes,
# SHA256 5e98cc51659cdf3fd0edcdf076137893575f4840a5fa6dcb2f460f93c8669c43,
# config.json guid asc.{9DC93CDB-B576-4F0C-B55E-FCC9C48DD007}, version 3.2.2.
ADD https://raw.githubusercontent.com/ONLYOFFICE/onlyoffice.github.io/master/sdkjs-plugins/content/ai/deploy/ai.plugin /tmp/ai.plugin
RUN set -eux; \
    echo "5e98cc51659cdf3fd0edcdf076137893575f4840a5fa6dcb2f460f93c8669c43  /tmp/ai.plugin" | sha256sum -c -; \
    mkdir -p /var/www/onlyoffice/documentserver/sdkjs-plugins/ai; \
    if command -v unzip >/dev/null 2>&1; then \
        unzip -o -q /tmp/ai.plugin -d /var/www/onlyoffice/documentserver/sdkjs-plugins/ai; \
    else \
        python3 -c "import zipfile; zipfile.ZipFile('/tmp/ai.plugin').extractall('/var/www/onlyoffice/documentserver/sdkjs-plugins/ai')"; \
    fi; \
    rm /tmp/ai.plugin; \
    grep -q 'asc.{9DC93CDB-B576-4F0C-B55E-FCC9C48DD007}' /var/www/onlyoffice/documentserver/sdkjs-plugins/ai/config.json; \
    grep -q '"version": "3.2.2"' /var/www/onlyoffice/documentserver/sdkjs-plugins/ai/config.json; \
    echo "AI Tools plugin 3.2.2 installed"
