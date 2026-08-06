#!/usr/bin/env bash
# Architecture grep guards for recall-mobile. Must print nothing / exit 0.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
fail=0

check() {
  local label="$1"
  local pattern="$2"
  shift 2
  local hits
  hits="$(rg -n --glob '!**/tool/**' "$pattern" "$@" 2>/dev/null || true)"
  if [[ -n "$hits" ]]; then
    echo "FAIL: $label"
    echo "$hits"
    fail=1
  fi
}

# Views must not resolve services via Get.find.
check "views must not Get.find services" \
  'Get\.find<\w*Service>' \
  lib/modules/**/view/**

# Controllers must not hold SupabaseService.
check "controllers must not import/use SupabaseService" \
  'SupabaseService' \
  lib/modules/**/controller/**

# Paywall navigation only via TierService.
check "Routes.paywall navigation only in tier_service" \
  'Get\.(toNamed|offNamed|offAllNamed)\([^\)]*Routes\.paywall|Get\.(toNamed|offNamed|offAllNamed)\([^\)]*paywall' \
  lib --glob '!**/tier_service.dart' --glob '!**/app_routes.dart' --glob '!**/app_pages.dart'

# LimitsConfig reads: only config, tier_service, and boot/resume paths.
check "LimitsConfig only in allowed boot/config paths" \
  'LimitsConfig' \
  lib/modules \
  --glob '!**/splash/controller/splash_controller.dart'

if [[ "$fail" -ne 0 ]]; then
  echo "arch_check failed"
  exit 1
fi
echo "arch_check ok"
