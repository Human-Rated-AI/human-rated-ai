#!/bin/bash

# cleanup-favorites.sh - Remove orphaned favorites that reference deleted AI bots
# Usage: ./cleanup-favorites.sh <serviceAccount.json> [options]

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Node.js script path
CLEANUP_JS="$SCRIPT_DIR/cleanup-favorites.js"

# Check if cleanup-favorites.js exists
if [[ ! -f "$CLEANUP_JS" ]]; then
    echo -e "${RED}Error: cleanup-favorites.js not found in $SCRIPT_DIR${NC}" >&2
    echo "This script requires cleanup-favorites.js to be in the same directory" >&2
    exit 1
fi

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is required but not installed${NC}" >&2
    echo "Please install Node.js to run this script" >&2
    exit 1
fi

# Parse arguments
SERVICE_ACCOUNT=""
JS_ARGS=()

show_help() {
    echo "Usage: $0 <serviceAccount.json> [options]"
    echo ""
    echo "Remove orphaned favorites that reference deleted AI bots"
    echo ""
    echo "Arguments:"
    echo "  serviceAccount.json    Path to Firebase service account JSON file"
    echo ""
    echo "Options:"
    echo "  -y, --yes              Auto-confirm deletions without prompting"
    echo "  --dry-run              Show what would be deleted without making changes"
    echo "  -v, --verbose          Show verbose output"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ./serviceAccount.json"
    echo "  $0 ./serviceAccount.json --dry-run"
    echo "  $0 ./serviceAccount.json --yes --verbose"
    echo "  $0 ./serviceAccount.json --dry-run --verbose"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            JS_ARGS+=("--yes")
            shift
            ;;
        --dry-run)
            JS_ARGS+=("--dry-run")
            shift
            ;;
        -v|--verbose)
            JS_ARGS+=("--verbose")
            shift
            ;;
        -h|--help)
            show_help
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}" >&2
            echo "Use --help for usage information" >&2
            exit 1
            ;;
        *)
            if [[ -z "$SERVICE_ACCOUNT" ]]; then
                SERVICE_ACCOUNT="$1"
            else
                echo -e "${RED}Error: Too many arguments${NC}" >&2
                echo "Use --help for usage information" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if service account file was provided
if [[ -z "$SERVICE_ACCOUNT" ]]; then
    echo -e "${RED}Error: Service account file is required${NC}" >&2
    echo "Usage: $0 <serviceAccount.json> [options]" >&2
    echo "Use --help for more information" >&2
    exit 1
fi

# Check if service account file exists
if [[ ! -f "$SERVICE_ACCOUNT" ]]; then
    echo -e "${RED}Error: Service account file not found: $SERVICE_ACCOUNT${NC}" >&2
    exit 1
fi

# Check if firebase-admin is available
echo -e "${BLUE}🔧 Checking dependencies...${NC}"
if ! node -e "require('firebase-admin')" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  firebase-admin package not found${NC}"
    
    # Check if we're in a directory with package.json
    if [[ -f "$SCRIPT_DIR/package.json" ]]; then
        echo -e "${BLUE}📦 Installing dependencies from package.json...${NC}"
        cd "$SCRIPT_DIR"
        if npm install; then
            echo -e "${GREEN}✓ Dependencies installed successfully${NC}"
        else
            echo -e "${RED}❌ Failed to install dependencies${NC}" >&2
            echo "Please run: cd $SCRIPT_DIR && npm install" >&2
            exit 1
        fi
    else
        echo -e "${BLUE}📦 Installing firebase-admin package...${NC}"
        cd "$SCRIPT_DIR"
        if npm install firebase-admin; then
            echo -e "${GREEN}✓ firebase-admin installed successfully${NC}"
        else
            echo -e "${RED}❌ Failed to install firebase-admin package${NC}" >&2
            echo "Please run: npm install firebase-admin" >&2
            exit 1
        fi
    fi
else
    echo -e "${GREEN}✓ firebase-admin package found${NC}"
fi

echo

# Build the command to run
COMMAND=(node "$CLEANUP_JS" "$SERVICE_ACCOUNT")
COMMAND+=("${JS_ARGS[@]}")

# Show what command will be executed
echo -e "${BLUE}🚀 Executing: ${COMMAND[*]}${NC}"
echo

# Change to script directory to ensure proper module resolution
cd "$SCRIPT_DIR"

# Execute the Node.js script with all arguments
exec "${COMMAND[@]}"