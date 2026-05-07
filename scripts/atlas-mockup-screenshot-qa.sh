#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SIMULATOR_ID="${SIMULATOR_ID:-booted}"
BUNDLE_ID="${BUNDLE_ID:-com.dkang2000.Atlas}"
DERIVED_DATA="${DERIVED_DATA:-atlas-ios/.derived-data-mockup-forward-current}"
OUT_DIR="${1:-output/mockup-screenshot-qa/$(date +%Y%m%d-%H%M%S)}"
SETTLE_SECONDS="${ATLAS_QA_SETTLE_SECONDS:-3}"
ROUTE_SETTLE_SECONDS="${ATLAS_QA_ROUTE_SETTLE_SECONDS:-5}"
SLOW_ROUTE_SETTLE_SECONDS="${ATLAS_QA_SLOW_ROUTE_SETTLE_SECONDS:-8}"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/Atlas.app"

mkdir -p "$OUT_DIR"

xcodebuild \
  -project atlas-ios/Atlas.xcodeproj \
  -scheme Atlas \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$DERIVED_DATA" \
  build

xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

capture() {
  local name="$1"
  local tab="${2:-}"
  local route="${3:-}"
  local log_kind="${4:-}"
  local screenshot="$OUT_DIR/$name.png"
  local settle="$SETTLE_SECONDS"
  local env_args=("SIMCTL_CHILD_ATLAS_QA_MOCKUP_FIDELITY=1")

  if [[ -n "$tab" ]]; then
    env_args+=("SIMCTL_CHILD_ATLAS_QA_ACTIVE_TAB=$tab")
  fi

  if [[ -n "$route" ]]; then
    env_args+=("SIMCTL_CHILD_ATLAS_QA_ROUTE=$route")
    settle="$ROUTE_SETTLE_SECONDS"
  fi

  if [[ -n "$log_kind" ]]; then
    env_args+=("SIMCTL_CHILD_ATLAS_QA_LOG_KIND=$log_kind")
  fi

  case "$route" in
    reviewMode|weeklyReview|progressEvidence|settingsIntegrations)
      settle="$SLOW_ROUTE_SETTLE_SECONDS"
      ;;
    *)
      ;;
  esac

  xcrun simctl terminate "$SIMULATOR_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
  env "${env_args[@]}" xcrun simctl launch --terminate-running-process "$SIMULATOR_ID" "$BUNDLE_ID" --atlas-qa-mockup-fidelity >/dev/null
  sleep "$settle"
  xcrun simctl io "$SIMULATOR_ID" screenshot "$screenshot" >/dev/null
  verify_not_blank "$screenshot"
  printf '%s\n' "$screenshot"
}

verify_not_blank() {
  local screenshot="$1"
  python3 - "$screenshot" <<'PY'
import pathlib
import sys

try:
    from PIL import Image, ImageStat
except Exception:
    raise SystemExit(0)

path = pathlib.Path(sys.argv[1])
with Image.open(path) as image:
    rgb = image.convert("RGB")
    width, height = rgb.size
    sample = rgb.crop((0, int(height * 0.18), width, int(height * 0.88)))
    stat = ImageStat.Stat(sample)
    extrema = sample.getextrema()
    channel_range = sum(high - low for low, high in extrema)
    stddev = sum(stat.stddev)
    if channel_range < 36 or stddev < 18:
        print(f"Blank or near-blank screenshot captured: {path}", file=sys.stderr)
        raise SystemExit(7)
PY
}

capture today mockupToday
capture log mockupLog
capture check-in mockupLog "" symptom
capture protocols mockupProtocols
capture progress mockupProgress
capture companion mockupCompanion
capture protocol-detail "" protocolDetail
capture protocol-create "" protocolCreate
capture protocol-editor "" protocolEdit
capture protocol-change "" protocolChange
capture medication-levels "" medicationLevels
capture inventory "" inventory
capture calculator "" calculator
capture share-summary "" reviewMode
capture weekly-review "" weeklyReview
capture progress-evidence "" progressEvidence
capture settings-integrations "" settingsIntegrations
capture settings-account "" settingsAccount
capture settings-privacy "" settingsPrivacy
capture settings-reminders "" settingsNotifications
capture settings-companion "" settingsPersonalization
capture widgets "" watchCompanion
capture companion-detail "" mascot
capture rewards-detail "" rewards
capture import-records "" importFlow
capture quick-capture-shot "" quickCaptureShot
capture quick-capture-weight "" quickCaptureWeight
capture quick-capture-food "" quickCaptureFood
capture quick-capture-hydration "" quickCaptureHydration
capture quick-capture-protein "" quickCaptureProtein
capture quick-capture-checkin "" quickCaptureSymptom
capture quick-capture-photo "" quickCaptureProgressPhoto
capture export-data "" trustVault
capture support-logs "" insightsLogs
capture progress-review "" insightsAnalysis
capture health-signals "" labs
capture peptide-notes "" compoundIntelligence

cat > "$OUT_DIR/manifest.txt" <<MANIFEST
Atlas mockup screenshot QA
Output: $OUT_DIR
Simulator: $SIMULATOR_ID
Reference: ${REFERENCE_DIR:-not provided}

Primary tabs:
- today.png
- log.png
- check-in.png
- protocols.png
- progress.png
- companion.png

Deep flows:
- protocol-detail.png
- protocol-create.png
- protocol-editor.png
- protocol-change.png
- medication-levels.png
- inventory.png
- calculator.png
- share-summary.png
- weekly-review.png
- progress-evidence.png
- settings-integrations.png
- settings-account.png
- settings-privacy.png
- settings-reminders.png
- settings-companion.png
- widgets.png
- companion-detail.png
- rewards-detail.png
- import-records.png
- quick-capture-shot.png
- quick-capture-weight.png
- quick-capture-food.png
- quick-capture-hydration.png
- quick-capture-protein.png
- quick-capture-checkin.png
- quick-capture-photo.png
- export-data.png
- support-logs.png
- progress-review.png
- health-signals.png
- peptide-notes.png
MANIFEST

if [[ -n "${REFERENCE_DIR:-}" && -d "$REFERENCE_DIR" ]]; then
  python3 - "$REFERENCE_DIR" "$OUT_DIR" <<'PY'
import math
import pathlib
import sys

try:
    from PIL import Image, ImageChops
except Exception:
    print("Pixel diff skipped: Pillow is not available in this Python.")
    raise SystemExit(0)

reference = pathlib.Path(sys.argv[1])
current = pathlib.Path(sys.argv[2])
lines = ["Atlas mockup pixel diff", ""]

for current_path in sorted(current.glob("*.png")):
    reference_path = reference / current_path.name
    if not reference_path.exists():
        lines.append(f"{current_path.name}: no reference")
        continue

    with Image.open(reference_path) as a, Image.open(current_path) as b:
        if a.size != b.size:
            lines.append(f"{current_path.name}: size mismatch {a.size} vs {b.size}")
            continue

        diff = ImageChops.difference(a.convert("RGB"), b.convert("RGB"))
        histogram = diff.histogram()
        squares = (value * ((index % 256) ** 2) for index, value in enumerate(histogram))
        rms = math.sqrt(sum(squares) / float(a.size[0] * a.size[1] * 3))
        bbox = diff.getbbox()
        lines.append(f"{current_path.name}: rms={rms:.3f}, changed={'yes' if bbox else 'no'}")

(current / "pixel-diff.txt").write_text("\n".join(lines) + "\n")
print(current / "pixel-diff.txt")
PY
fi
