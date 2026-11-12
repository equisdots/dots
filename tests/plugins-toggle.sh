#!/usr/bin/env bash
# Regression test for `dots plugins enable|disable|migrate`.
# Runs the real dots script against a throwaway HOME/XDG_CONFIG_HOME and a fake
# hyprctl, so it never touches the live session or settings.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTS="$ROOT/dots"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dots-plugins-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export PATH="$TMP/bin:$PATH"

HYPR="$XDG_CONFIG_HOME/hypr"
mkdir -p "$HYPR/plugins/demo" "$HYPR/plugins/scoped" "$HYPR/plugins/custom" \
         "$HYPR/plugins/plain" "$HYPR/plugins/broken" "$TMP/bin"

# Keep enable/disable from reloading the real Hyprland session.
printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/bin/hyprctl"
chmod +x "$TMP/bin/hyprctl"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
ok() { printf 'ok: %s\n' "$*"; }
assert_jq() { jq -e "$2" "$1" >/dev/null 2>&1 || fail "$3"; }

printf '%s\n' '{"id":"demo","name":"Demo","version":"0.1.0","type":"shell","scope":"demo","defaultEnabled":true}' > "$HYPR/plugins/demo/plugin.json"
printf '%s\n' '{"id":"scoped","name":"Scoped","version":"0.1.0","type":"shell","scope":"scoped.scope","defaultEnabled":true}' > "$HYPR/plugins/scoped/plugin.json"
printf '%s\n' '{"id":"custom","name":"Custom","version":"0.1.0","type":"shell","toggle":"custom.on","defaultEnabled":true}' > "$HYPR/plugins/custom/plugin.json"
printf '%s\n' '{"id":"plain","name":"Plain","version":"0.1.0","type":"shell","defaultEnabled":true}' > "$HYPR/plugins/plain/plugin.json"
printf '%s\n' '{"id":"broken","name":"Broken","version":"0.1.0","type":"shell","defaultEnabled":true}' > "$HYPR/plugins/broken/plugin.json"

printf '%s\n' '{"demo":{"enabled":true},"extra":1}' > "$HYPR/plugins/demo/settings.json"
printf '%s\n' '{"scoped":{"scope":{"enabled":true}}}' > "$HYPR/plugins/scoped/settings.json"
printf '%s\n' '{"custom":{"on":true}}' > "$HYPR/plugins/custom/settings.json"
printf '%s\n' '{not valid json' > "$HYPR/plugins/broken/settings.json"

printf '%s\n' '{"bar":{"palette":"x"},"keep":{"x":1},"plugins":{"demo":{"enabled":false,"config":false},"scoped":{"enabled":false,"config":false},"custom":{"enabled":false,"config":false},"other":{"enabled":true}}}' > "$HYPR/settings.json"

run() { bash "$DOTS" "$@"; }

# 1. The legacy core block is cleaned on the first plugins command; plugin
#    state comes from the plugin's own file (not from the core enabled:false).
run plugins list >/dev/null
run plugins migrate >/dev/null
assert_jq "$HYPR/settings.json" '
    (.plugins.demo.config == false)
    and (.plugins.scoped.config == false)
    and (.plugins.custom.config == false)
    and (.plugins.other == null)
    and ([.plugins[]? | select(type == "object") | .enabled | select(. != null)] | length == 0)
    and (.bar.palette == "x")
' "legacy enabled keys removed, config/bar preserved"

cp "$HYPR/settings.json" "$TMP/core-baseline.json"

# 2. list reads the plugin settings, including scope/toggle/defaults.
list="$(run plugins list)"
grep -Eq '^  demo .* enabled' <<< "$list" || fail "demo should be enabled from its own settings"
grep -Eq '^  scoped .* enabled' <<< "$list" || fail "scoped should resolve its scope toggle"
grep -Eq '^  custom .* enabled' <<< "$list" || fail "custom should resolve its manifest toggle"
grep -Eq '^  plain .* enabled' <<< "$list" || fail "plain should use defaultEnabled"
grep -Eq '^  broken .* enabled' <<< "$list" || fail "invalid settings should fall back to defaultEnabled"
ok "list resolves plugin settings (scope, toggle, defaults)"

# 3. disable/enable writes the plugin's own settings and preserves extra keys.
run plugins disable demo >/dev/null
assert_jq "$HYPR/plugins/demo/settings.json" '.demo.enabled == false and .extra == 1' \
    "demo disable must write its own settings and preserve unknown keys"
grep -Eq '^  demo .* disabled' <<< "$(run plugins list)" || fail "demo should be disabled"
run plugins enable demo >/dev/null
assert_jq "$HYPR/plugins/demo/settings.json" '.demo.enabled == true' "demo enable"
grep -Eq '^  demo .* enabled' <<< "$(run plugins list)" || fail "demo should be enabled again"
ok "enable/disable writes the plugin settings"

# 4. The core settings (except the legacy block) are untouched.
jq -S 'del(.plugins)' "$HYPR/settings.json" > "$TMP/core-now.json"
jq -S 'del(.plugins)' "$TMP/core-baseline.json" > "$TMP/core-before.json"
cmp -s "$TMP/core-before.json" "$TMP/core-now.json" || fail "enable/disable modified the core settings"
ok "core settings untouched by toggles"

# 5. Scope and custom toggle paths.
run plugins disable scoped >/dev/null
assert_jq "$HYPR/plugins/scoped/settings.json" '.scoped.scope.enabled == false' \
    "scope toggle must resolve to scoped.scope.enabled"
run plugins disable custom >/dev/null
assert_jq "$HYPR/plugins/custom/settings.json" '.custom.on == false' \
    "manifest toggle must resolve to custom.on"
run plugins disable plain >/dev/null
assert_jq "$HYPR/plugins/plain/settings.json" '.plugins.plain.enabled == false' \
    "default toggle path must be plugins.<id>.enabled"
ok "scope/toggle/default paths"

# 6. Invalid JSON is rejected without corrupting the file.
before="$(sha256sum "$HYPR/plugins/broken/settings.json" | cut -d' ' -f1)"
if run plugins disable broken >/dev/null 2>&1; then
    fail "disable must fail on invalid plugin settings"
fi
after="$(sha256sum "$HYPR/plugins/broken/settings.json" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || fail "invalid settings file was modified"
ok "invalid plugin settings rejected safely"

# 7. Migration is idempotent.
before="$(sha256sum "$HYPR/settings.json" | cut -d' ' -f1)"
run plugins migrate >/dev/null
after="$(sha256sum "$HYPR/settings.json" | cut -d' ' -f1)"
[[ "$before" == "$after" ]] || fail "migrate rewrote an already-clean settings.json"
ok "migration is idempotent"

printf 'PLUGINS TOGGLE TEST: OK\n'
