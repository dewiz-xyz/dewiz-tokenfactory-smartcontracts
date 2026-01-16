#!/bin/bash
# Trail of Bits Security Analysis Script for Dewiz Token Factory
# This script runs various security analysis tools from Trail of Bits

set -e

echo "=== Dewiz Token Factory Security Analysis ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Slither is installed
if ! command -v slither &> /dev/null; then
    echo -e "${RED}Error: Slither is not installed${NC}"
    echo "Install with: pip install slither-analyzer"
    exit 1
fi

echo -e "${GREEN}1. Running Slither Static Analysis...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
slither . --exclude-dependencies || echo -e "${YELLOW}Slither found issues (see above)${NC}"
echo ""

echo -e "${GREEN}2. Running Slither Detectors (High/Medium only)...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
slither . --exclude-dependencies --detect reentrancy-eth,reentrancy-no-eth,controlled-delegatecall,uninitialized-state,uninitialized-storage,arbitrary-send || echo -e "${YELLOW}Detectors found issues${NC}"
echo ""

echo -e "${GREEN}3. Running Slither Code Quality Checks...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
slither . --exclude-dependencies --detect naming-convention,solc-version,pragma || echo -e "${YELLOW}Code quality issues found${NC}"
echo ""

echo -e "${GREEN}4. Generating Human-Readable Summary...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
slither . --exclude-dependencies --print human-summary > slither-report.txt 2>&1 || true
if [ -f slither-report.txt ]; then
    cat slither-report.txt
    echo -e "${GREEN}Full report saved to: slither-report.txt${NC}"
fi
echo ""

echo -e "${GREEN}5. Checking for Contract Complexity...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
slither . --exclude-dependencies --print function-summary > function-summary.txt 2>&1 || true
if [ -f function-summary.txt ]; then
    echo "Function summary saved to: function-summary.txt"
fi
echo ""

echo -e "${GREEN}=== Security Analysis Complete ===${NC}"
echo ""
echo "Reports generated:"
echo "  - slither-report.txt: Full analysis report"
echo "  - function-summary.txt: Function complexity analysis"
echo ""
echo -e "${YELLOW}Recommendation: Review all findings before deployment${NC}"
