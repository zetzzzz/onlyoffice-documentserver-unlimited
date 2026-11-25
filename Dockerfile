# OnlyOffice DocumentServer 10.0.0.1 with Mobile Edit enabled.
# Unofficial build: a thin layer on top of the official image.
#
# Why this exists:
# - The thomisus "unlimited" fork (ghcr.io/thomisus/onlyoffice-documentserver-unlimited)
#   is stuck at 9.2.1: its .deb releases stopped there, so its Dockerfile
#   cannot be bumped to newer versions.
# - The official 9.4+ builds already removed the 20-connection limit,
#   so the only remaining feature of the "unlimited" fork is Mobile Edit.
# - This image takes the official 10.0.0.1 image and flips the Mobile Edit
#   flag in the mobile web-apps, nothing else.
#
# The build FAILS if the patch does not apply, so a silent no-op
# (e.g. upstream renamed the flag) can never ship.
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
