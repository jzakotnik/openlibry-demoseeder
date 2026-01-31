# OpenLibry Demo Data Seeder

A lightweight Docker container that seeds an OpenLibry instance with demo data for presentations and testing.

## What it creates

### 5 Users (Superhero names)

| ID   | Name             | Grade | Teacher      |
|------|------------------|-------|--------------|
| 8001 | Peter Parker     | 3a    | Herr Stark   |
| 8002 | Diana Prince     | 4b    | Frau Wayne   |
| 8003 | Bruce Banner     | 2c    | Herr Rogers  |
| 8004 | Natasha Romanoff | 3b    | Frau Fury    |
| 8005 | Clark Kent       | 4a    | Herr Lane    |

### 10 Books (German Youth Literature Classics)

| ID   | Title                                    | Author           |
|------|------------------------------------------|------------------|
| 9001 | Die unendliche Geschichte               | Michael Ende     |
| 9002 | Momo                                     | Michael Ende     |
| 9003 | Jim Knopf und Lukas der Lokomotivführer | Michael Ende     |
| 9004 | Das doppelte Lottchen                   | Erich Kästner    |
| 9005 | Emil und die Detektive                  | Erich Kästner    |
| 9006 | Tintenherz                               | Cornelia Funke   |
| 9007 | Die wilden Hühner                        | Cornelia Funke   |
| 9008 | Der Räuber Hotzenplotz                  | Otfried Preußler |
| 9009 | Die kleine Hexe                          | Otfried Preußler |
| 9010 | Krabat                                   | Otfried Preußler |

### 2 Active Rentals

- "Die unendliche Geschichte" → Peter Parker
- "Emil und die Detektive" → Bruce Banner

## Usage

### Build the image

```bash
docker build -t openlibry-demo-seeder .
```

### Run against local OpenLibry

```bash
# If OpenLibry is running on localhost:3000
docker run --rm --network host openlibry-demo-seeder

# If OpenLibry is running on a different port
docker run --rm --network host -e OPENLIBRY_URL=http://localhost:3001 openlibry-demo-seeder
```

### Run with Docker Compose

Add to your `docker-compose.yml`:

```yaml
services:
  openlibry:
    image: openlibry:latest
    ports:
      - "3000:3000"
    # ... other config

  demo-seeder:
    image: openlibry-demo-seeder
    depends_on:
      - openlibry
    environment:
      - OPENLIBRY_URL=http://openlibry:3000
      - WAIT_TIMEOUT=120
```

Then run:

```bash
docker-compose up -d openlibry
docker-compose run --rm demo-seeder
```

## Configuration

| Environment Variable | Default                  | Description                              |
|---------------------|--------------------------|------------------------------------------|
| `OPENLIBRY_URL`     | `http://localhost:3000`  | Base URL of the OpenLibry instance       |
| `WAIT_TIMEOUT`      | `60`                     | Seconds to wait for OpenLibry to be ready |
| `SKIP_COVERS`       | `false`                  | Skip downloading and uploading covers    |

## How it works

1. **Wait** - Polls OpenLibry's `/api/user` endpoint until it responds (or timeout)
2. **Create Users** - POST to `/api/user` for each superhero
3. **Create Books** - POST to `/api/book` for each German classic
4. **Upload Covers** - Downloads covers from OpenLibrary.org by ISBN, uploads to `/api/book/cover/{id}`
5. **Create Rentals** - POST to `/api/book/{bookId}/user/{userId}` for 2 rentals
6. **Exit** - Container exits after seeding completes

## Notes

- The seeder is **idempotent** - it can be run multiple times safely. Existing records will cause warnings but won't fail the script.
- Book covers are fetched from [OpenLibrary Covers API](https://openlibrary.org/dev/docs/api/covers) using ISBNs.
- If a cover isn't available, the book is still created without a cover image.

## Building for multiple architectures

```bash
# Build for both AMD64 and ARM64 (for Raspberry Pi)
docker buildx build --platform linux/amd64,linux/arm64 -t openlibry-demo-seeder:latest --push .
```
