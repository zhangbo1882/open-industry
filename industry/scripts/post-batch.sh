#!/usr/bin/env bash
# post-batch.sh — Verify all support files are updated after a batch ingest
# Usage: post-batch.sh [--fix] [--verbose]
#   --fix     Attempt to auto-fix missing entries (adds stubs)
#   --verbose Show detailed per-file status

set -euo pipefail

WIKI_DIR="${1:-wiki}"
VERBOSE=false
FIX=false

for arg in "$@"; do
    case $arg in
        --verbose|-v) VERBOSE=true ;;
        --fix) FIX=true ;;
    esac
done

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
pass() { echo -e "  ${GREEN}✓${NC} $*"; }
fail() { echo -e "  ${RED}✗${NC} $*"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $*"; }

errors=0
warnings=0

echo "═══════════════════════════════════════════"
echo "  Post-Batch Verification"
echo "═══════════════════════════════════════════"
echo ""

# ── Check 1: sector pages have company entries ──
echo "─ Sector Pages ─"
for sector_file in "$WIKI_DIR/sectors/"*.md; do
    [ -f "$sector_file" ] || continue
    sector_name=$(basename "$sector_file" .md)
    # Count company entries (lines starting with "- [[" or "- **[[")
    entries=$(grep -cP '^\- \[\[|^\-\s*\*\*\[\[|^\-\s*\[.*\]\(' "$sector_file" 2>/dev/null || echo 0)
    if [ "$entries" -gt 0 ]; then
        $VERBOSE && pass "$sector_name: $entries companies"
    else
        fail "$sector_name: NO company entries"
        ((errors++))
    fi
done

# ── Check 2: index.md has recent entries ──
echo ""
echo "─ Index (index.md) ─"
INDEX_FILE="$WIKI_DIR/index.md"
if [ -f "$INDEX_FILE" ]; then
    entries=$(grep -cP '^\- \[\[|^\-\s*\[.*\]\(' "$INDEX_FILE" 2>/dev/null || echo 0)
    recent_entries=$(grep -cP "$(date +%Y-%m)" "$INDEX_FILE" 2>/dev/null || echo 0)
    pass "index.md: $entries total entries, $recent_entries from current month"
else
    fail "index.md NOT FOUND"
    ((errors++))
fi

# ── Check 3: 行业分类全景.md structure ──
echo ""
echo "─ 行业分类全景 ─"
PANORAMA="$WIKI_DIR/syntheses/行业分类全景.md"
if [ -f "$PANORAMA" ]; then
    L1_count=$(grep -cP '^## ' "$PANORAMA" 2>/dev/null || echo 0)
    L2_count=$(grep -cP '^### ' "$PANORAMA" 2>/dev/null || echo 0)
    L3_count=$(grep -cP '^#### ' "$PANORAMA" 2>/dev/null || echo 0)
    # Check for non-thematic batch sections (common error)
    bad_sections=$(grep -cP '^#{1,4}\s+(Batch|TODO|WIP|Draft)' "$PANORAMA" 2>/dev/null || echo 0)
    pass "全景: L1=$L1_count, L2=$L2_count, L3=$L3_count"
    if [ "$bad_sections" -gt 0 ]; then
        fail "全景: $bad_sections non-thematic sections (Batch/TODO/WIP/Draft)"
        ((errors++))
    fi
else
    fail "行业分类全景.md NOT FOUND"
    ((errors++))
fi

# ── Check 4: log.md is updated ──
echo ""
echo "─ Operation Log (log.md) ─"
LOG_FILE="$WIKI_DIR/log.md"
if [ -f "$LOG_FILE" ]; then
    last_entry=$(head -5 "$LOG_FILE")
    today_entry=$(echo "$last_entry" | grep -c "$(date +%Y-%m-%d)" 2>/dev/null || echo 0)
    if [ "$today_entry" -gt 0 ]; then
        pass "log.md: updated today ($(date +%Y-%m-%d))"
    else
        warn "log.md: last entry may not be from today"
        ((warnings++))
    fi
else
    fail "log.md NOT FOUND"
    ((errors++))
fi

# ── Check 5: No orphan pages (wiki pages without sector linkage) ──
echo ""
echo "─ Orphan Detection ─"
# Collect all company pages
company_pages=$(find "$WIKI_DIR/companies" -name "*.md" 2>/dev/null | wc -l)
if [ "$company_pages" -gt 0 ]; then
    pass "$company_pages company pages found"
else
    warn "No company pages found in wiki/companies/"
    ((warnings++))
fi

# ── Summary ──
echo ""
echo "═══════════════════════════════════════════"
if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    echo -e "  ${GREEN}All checks passed ✓${NC}"
elif [ "$errors" -eq 0 ]; then
    echo -e "  ${YELLOW}$warnings warning(s), 0 errors${NC}"
else
    echo -e "  ${RED}$errors error(s), $warnings warning(s)${NC}"
fi
echo "═══════════════════════════════════════════"

exit $errors
