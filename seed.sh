#!/bin/sh
set -e

# Configuration
OPENLIBRY_URL="${OPENLIBRY_URL:-http://localhost:3000}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-60}"
SKIP_COVERS="${SKIP_COVERS:-false}"
COVER_DELAY="${COVER_DELAY:-3}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Wait for OpenLibry to be available
wait_for_openlibry() {
    log_info "Waiting for OpenLibry at ${OPENLIBRY_URL}..."
    
    elapsed=0
    while [ $elapsed -lt $WAIT_TIMEOUT ]; do
        if curl -sf "${OPENLIBRY_URL}/api/user" > /dev/null 2>&1; then
            log_success "OpenLibry is ready!"
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
        echo -n "."
    done
    
    echo ""
    log_error "Timeout waiting for OpenLibry after ${WAIT_TIMEOUT}s"
    exit 1
}

# Create a user
create_user() {
    local id="$1"
    local firstName="$2"
    local lastName="$3"
    local grade="$4"
    local teacher="$5"
    
    log_info "Creating user: ${firstName} ${lastName} (ID: ${id})"
    
    response=$(curl -sf --max-time 15 -X POST "${OPENLIBRY_URL}/api/user" \
        -H "Content-Type: application/json" \
        -d "{
            \"id\": ${id},
            \"firstName\": \"${firstName}\",
            \"lastName\": \"${lastName}\",
            \"schoolGrade\": \"${grade}\",
            \"schoolTeacherName\": \"${teacher}\",
            \"active\": true
        }" 2>&1) || {
        log_warn "User ${id} may already exist or creation failed"
        return 0
    }
    
    log_success "Created user: ${firstName} ${lastName}"
    sleep 0.5
}

# Create a book
create_book() {
    local id="$1"
    local title="$2"
    local author="$3"
    local isbn="$4"
    local topics="$5"
    
    log_info "Creating book: ${title} (ID: ${id})"
    
    response=$(curl -sf --max-time 15 -X POST "${OPENLIBRY_URL}/api/book" \
        -H "Content-Type: application/json" \
        -d "{
            \"id\": ${id},
            \"title\": \"${title}\",
            \"author\": \"${author}\",
            \"isbn\": \"${isbn}\",
            \"topics\": \"${topics}\",
            \"rentalStatus\": \"available\",
            \"renewalCount\": 0
        }" 2>&1) || {
        log_warn "Book ${id} may already exist or creation failed"
        return 0
    }
    
    log_success "Created book: ${title}"
    sleep 0.5
}

# Fetch cover using OpenLibry's API (tries DNB, then OpenLibrary)
fetch_cover() {
    local book_id="$1"
    local isbn="$2"
    local title="$3"
    
    if [ "$SKIP_COVERS" = "true" ]; then
        log_info "Skipping cover for: ${title}"
        return 0
    fi
    
    log_info "Fetching cover for: ${title} (ISBN: ${isbn})"
    
    # Add delay before request to avoid overwhelming the server
    sleep "$COVER_DELAY"
    
    # Use OpenLibry's fetchCover API (tries DNB first, then OpenLibrary)
    response=$(curl -sf --max-time 30 \
        "${OPENLIBRY_URL}/api/book/fetchCover?isbn=${isbn}&bookId=${book_id}" 2>&1)
    
    if [ $? -eq 0 ]; then
        # Check if response indicates success
        if echo "$response" | grep -q '"success":true'; then
            source=$(echo "$response" | grep -o '"source":"[^"]*"' | cut -d'"' -f4)
            log_success "Uploaded cover for: ${title} (source: ${source:-unknown})"
        else
            log_warn "No cover found for: ${title}"
        fi
    else
        log_warn "Failed to fetch cover for: ${title}"
    fi
    
    # Small delay after each cover operation
    sleep 1
}

# Rent a book to a user
rent_book() {
    local book_id="$1"
    local user_id="$2"
    local book_title="$3"
    local user_name="$4"
    
    log_info "Renting '${book_title}' to ${user_name}"
    
    response=$(curl -sf -X POST "${OPENLIBRY_URL}/api/book/${book_id}/user/${user_id}" \
        -H "Content-Type: application/json" 2>&1) || {
        log_warn "Rental may have failed for book ${book_id} to user ${user_id}"
        return 0
    }
    
    log_success "Rented '${book_title}' to ${user_name}"
}

# Main execution
main() {
    echo ""
    echo "========================================"
    echo "  OpenLibry Demo Data Seeder"
    echo "========================================"
    echo ""
    
    wait_for_openlibry
    
    echo ""
    echo "--- Creating Users ---"
    echo ""
    
    # Create 5 superhero users
    create_user 8001 "Peter" "Parker" "3a" "Herr Stark"
    create_user 8002 "Diana" "Prince" "4b" "Frau Wayne"
    create_user 8003 "Bruce" "Banner" "2c" "Herr Rogers"
    create_user 8004 "Natasha" "Romanoff" "3b" "Frau Fury"
    create_user 8005 "Clark" "Kent" "4a" "Herr Lane"
    
    echo ""
    echo "--- Creating Books ---"
    echo ""
    
    # Create 10 famous German youth literature books
    # Format: create_book ID "Title" "Author" "ISBN" "Topics"
    create_book 9001 "Die unendliche Geschichte" "Michael Ende" "9783522202503" "Fantasy, Abenteuer"
    create_book 9002 "Momo" "Michael Ende" "9783522202107" "Fantasy, Zeit"
    create_book 9003 "Jim Knopf und Lukas der Lokomotivführer" "Michael Ende" "9783522184908" "Abenteuer, Freundschaft"
    create_book 9004 "Das doppelte Lottchen" "Erich Kästner" "9783791530116" "Familie, Zwillinge"
    create_book 9005 "Emil und die Detektive" "Erich Kästner" "9783791530109" "Krimi, Berlin"
    create_book 9006 "Tintenherz" "Cornelia Funke" "9783791504650" "Fantasy, Bücher"
    create_book 9007 "Die wilden Hühner" "Cornelia Funke" "9783791504759" "Freundschaft, Schule"
    create_book 9008 "Der Räuber Hotzenplotz" "Otfried Preußler" "9783522105903" "Abenteuer, Humor"
    create_book 9009 "Die kleine Hexe" "Otfried Preußler" "9783522105804" "Fantasy, Magie"
    create_book 9010 "Krabat" "Otfried Preußler" "9783522200936" "Fantasy, Sage"
    
    echo ""
    echo "--- Fetching Book Covers ---"
    echo ""
    
    # Fetch covers for all books using OpenLibry's API
    fetch_cover 9001 "9783522202503" "Die unendliche Geschichte"
    fetch_cover 9002 "9783522202107" "Momo"
    fetch_cover 9003 "9783522184908" "Jim Knopf und Lukas der Lokomotivführer"
    fetch_cover 9004 "9783791530116" "Das doppelte Lottchen"
    fetch_cover 9005 "9783791530109" "Emil und die Detektive"
    fetch_cover 9006 "9783791504650" "Tintenherz"
    fetch_cover 9007 "9783791504759" "Die wilden Hühner"
    fetch_cover 9008 "9783522105903" "Der Räuber Hotzenplotz"
    fetch_cover 9009 "9783522105804" "Die kleine Hexe"
    fetch_cover 9010 "9783522200936" "Krabat"
    
    echo ""
    echo "--- Creating Rentals ---"
    echo ""
    
    # Rent 2 books
    rent_book 9001 8001 "Die unendliche Geschichte" "Peter Parker"
    rent_book 9005 8003 "Emil und die Detektive" "Bruce Banner"
    
    echo ""
    echo "========================================"
    echo "  Demo Data Seeding Complete!"
    echo "========================================"
    echo ""
    echo "Created:"
    echo "  - 5 users (superhero names)"
    echo "  - 10 books (German youth classics)"
    echo "  - 2 active rentals"
    echo ""
    echo "User IDs: 8001-8005"
    echo "Book IDs: 9001-9010"
    echo ""
}

main "$@"