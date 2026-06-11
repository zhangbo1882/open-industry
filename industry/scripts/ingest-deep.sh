#!/usr/bin/env bash
# ingest-deep.sh — Open-Industry Deep Ingest Pipeline
# Usage: ingest-deep.sh <pdf_path> <stock_code> <company_name>
# Example: ingest-deep.sh "raw/reports/SZ000800_一汽解放_2025年年度报告.pdf" "SZ000800" "一汽解放"
#
# Pipeline: pdftotext → grep financial data → extract numbers → generate wiki page

# -e removed: annual report formats vary wildly; we handle errors manually
set -uo pipefail

PDF_PATH="${1:?Usage: ingest-deep.sh <pdf_path> <stock_code> <company_name>}"
STOCK_CODE="${2:?}"
COMPANY_NAME="${3:?}"

TMPDIR="${TMPDIR:-/tmp}"
TEXT_FILE="${TMPDIR}/${COMPANY_NAME}_ingest.txt"
OUTPUT_DIR="wiki/companies/a-share"
OUTPUT_FILE="${OUTPUT_DIR}/${COMPANY_NAME}.md"
TODAY=$(date +%Y-%m-%d)

# ── Color helpers ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[ingest]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
err()   { echo -e "${RED}[error]${NC} $*"; }

# ── Step 1: PDF to text ──
info "Step 1: pdftotext -layout $PDF_PATH → $TEXT_FILE"
if ! command -v pdftotext &>/dev/null; then
    err "pdftotext not found. Install: sudo apt install poppler-utils"
    exit 1
fi
pdftotext -layout "$PDF_PATH" "$TEXT_FILE" || {
    err "pdftotext failed on $PDF_PATH"
    exit 1
}
line_count=$(wc -l < "$TEXT_FILE")
info "  Extracted $line_count lines of text."

# ── Step 2: Keyword search ──
info "Step 2: Locating financial data..."

# Detect language: if text contains common Chinese financial terms, use CN; else EN
if grep -qP '营业收入|净利润|毛利率|研发费用' "$TEXT_FILE"; then
    LANG="cn"
    info "  Detected: Chinese annual report"
    # Chinese keywords → line number extraction patterns
    declare -A PATTERNS
    PATTERNS[revenue]='营业收入|营业总收入'
    PATTERNS[net_profit]='归属于.*净利润|归母净利润|归属于母公司'
    PATTERNS[deducted_profit]='扣非.*净利润|扣除非经常性损益'
    PATTERNS[operating_cf]='经营活动.*现金流|经营现金流'
    PATTERNS[eps]='基本每股收益'
    PATTERNS[roe]='加权平均.*净资产收益率|加权.*ROE|净资产收益率'
    PATTERNS[total_assets]='资产总计|总资产'
    PATTERNS[net_assets]='归属于.*净资产|归母净资产'
    PATTERNS[gross_margin]='综合毛利率|毛利率'
    PATTERNS[rd_expense]='研发费用|研发投入'
    PATTERNS[rd_ratio]='研发.*占.*营收.*比例|研发投入.*占.*比例'

    # Revenue breakdown keywords
    REV_BREAKDOWN_START='分产品|分行业|主营业务分产品|营业收入构成'
    REV_BREAKDOWN_END='分地区|主营业务分地区|研发投入|客户.*供应商|前五名'

    # Customer/supplier keywords
    CUST_TOP5='前五名客户|前五客户'
    SUPPLIER_TOP5='前五名供应商|前五供应商'

    # Compare year header
    YEAR_HEADER='2025.*年.*2024.*年|2025.*2024|项目.*2025'
    YEAR_NOW='2025年'
    YEAR_PREV='2024年'

else
    LANG="en"
    info "  Detected: English annual report"
    declare -A PATTERNS
    PATTERNS[revenue]='Revenue|Operating revenue|Total revenue'
    PATTERNS[net_profit]='Net profit.*attributable|Profit.*attributable.*shareholders|Net profit'
    PATTERNS[deducted_profit]='Deducted.*non-recurring|Non-recurring.*deducted|Recurring.*profit'
    PATTERNS[operating_cf]='Cash flow.*operating|Operating.*cash flow|Net cash.*operating'
    PATTERNS[eps]='Basic earnings per share|Earnings per share|EPS'
    PATTERNS[roe]='ROE|Return on equity|Weighted.*ROE'
    PATTERNS[total_assets]='Total assets'
    PATTERNS[net_assets]='Net assets.*attributable|Equity.*attributable.*shareholders'
    PATTERNS[gross_margin]='Gross margin|Gross profit margin'
    PATTERNS[rd_expense]='R&D.*expense|Research.*development.*expense'
    PATTERNS[rd_ratio]='R&D.*ratio|R&D.*percentage.*revenue'

    REV_BREAKDOWN_START='Revenue.*by.*product|Segment.*revenue|Revenue breakdown'
    REV_BREAKDOWN_END='Revenue.*by.*region|Geographic|R&D|Customer.*concentration|Major customers'

    CUST_TOP5='Major customers|Top.*customers|Customer.*concentration'
    SUPPLIER_TOP5='Major suppliers|Top.*suppliers|Supplier.*concentration'

    YEAR_HEADER='2025.*2024|For the year.*2025'
    YEAR_NOW='2025'
    YEAR_PREV='2024'
fi

# Helper: find line number of first match for a pattern
find_line() {
    local pattern="$1"
    local result
    result=$(grep -nP "$pattern" "$TEXT_FILE" | head -1 | cut -d: -f1)
    echo "${result:-0}"
}

# ── Step 3: Locate data, output context (semi-automated) ──
info "Step 3: Locating financial data lines..."

# ── Cleanup: remove stale helper functions (no longer used in semi-auto mode) ──
# parse_billion and extract_number_at removed — context display replaces auto-extraction.

# Semi-automated extraction: locate data lines, output context for manual review
# Annual report formats vary too much for reliable numeric extraction via grep.
# The script saves the grep/sed/search time; human/agent fills in the numbers.
info ""
info "═══════════════════════════════════════════════════════"
info "  Financial Data Locator — ${COMPANY_NAME} (${STOCK_CODE})"
info "  Review context below and fill wiki template manually"
info "═══════════════════════════════════════════════════════"

for key in revenue net_profit deducted_profit operating_cf eps roe total_assets net_assets gross_margin rd_expense rd_ratio; do
    line=$(find_line "${PATTERNS[$key]}")
    if [ "$line" -gt 0 ]; then
        printf "\n  ── %s (line %s) ──\n" "$key" "$line"
        sed -n "$((line>2 ? line-2 : 1)),$((line+3))p" "$TEXT_FILE" | head -6 | while IFS= read -r ctx; do
            echo "     | $ctx"
        done
    else
        warn "  %-20s → NOT FOUND" "$key"
    fi
done

# ── Revenue breakdown section ──
info ""
info "── Revenue Breakdown ──"
REV_START=$(find_line "$REV_BREAKDOWN_START")
REV_END_LINE=$(grep -nP "$REV_BREAKDOWN_END" "$TEXT_FILE" | head -1 | cut -d: -f1)
REV_END_LINE="${REV_END_LINE:-$((REV_START + 50))}"

if [ "$REV_START" -gt 0 ]; then
    info "  Revenue breakdown section: lines $REV_START–$REV_END_LINE"
    sed -n "${REV_START},${REV_END_LINE}p" "$TEXT_FILE" | head -40
else
    warn "  Revenue breakdown section NOT FOUND."
fi

# ── Customer/Supplier section ──
info ""
info "── Customer & Supplier Concentration ──"
CUST_LINE=$(find_line "$CUST_TOP5")
SUPP_LINE=$(find_line "$SUPPLIER_TOP5")
if [ "$CUST_LINE" -gt 0 ]; then
    info "  Customer section starts at line $CUST_LINE"
    sed -n "$((CUST_LINE-1)),$((CUST_LINE+12))p" "$TEXT_FILE" | head -20
else
    warn "  Customer concentration NOT FOUND."
fi

if [ "$SUPP_LINE" -gt 0 ]; then
    info "  Supplier section starts at line $SUPP_LINE"
    sed -n "$((SUPP_LINE-1)),$((SUPP_LINE+12))p" "$TEXT_FILE" | head -20
fi

info ""
info "═══════════════════════════════════════════════════════"
info "  Extraction complete. Review above data, then manually"
info "  fill the wiki template and save to:"
info "    $OUTPUT_FILE"
info "═══════════════════════════════════════════════════════"

# ── Cleanup ──
# Keep TEXT_FILE for manual review; user can delete later
info "Raw text kept at: $TEXT_FILE"
