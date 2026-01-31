# Week 1 - Proof of Concept ✅

**Status:** COMPLETE

## What We Built

A working NNTPS reader proof-of-concept with:
- ✅ Elixir NNTPS client (secure TLS connection, RFC 3977)
- ✅ HTTP REST API (connects backend to frontend)
- ✅ ReScript TEA frontend (React-based UI)
- ✅ Full round-trip: connect to server → fetch article → display

## Running the Application

### 1. Start the Backend (Terminal 1)

```bash
cd ~/Documents/hyperpolymath-repos/no-nonsense-nntps
mix deps.get
mix compile
iex -S mix
```

The HTTP API will start on `http://localhost:4000`

### 2. Build & Serve the Frontend (Terminal 2)

```bash
cd ~/Documents/hyperpolymath-repos/no-nonsense-nntps/frontend
deno task build
deno task serve
```

The frontend will be available at `http://localhost:8000`

### 3. Test the Application

1. Open your browser to `http://localhost:8000`
2. Enter an NNTPS server (default: `news.eternal-september.org`)
3. Click **Connect**
4. Enter an article Message-ID (e.g., `<test@example.com>`)
5. Click **Fetch** to view the article

## Architecture

```
┌─────────────────────────────────────┐
│  ReScript TEA Frontend (Port 8000)  │
│  - Connection form                  │
│  - Article viewer                   │
└──────────┬──────────────────────────┘
           │ HTTP/JSON
           │ (fetch API)
┌──────────▼──────────────────────────┐
│  Elixir HTTP API (Port 4000)        │
│  - POST /api/connect                │
│  - GET /api/articles/:id            │
└──────────┬──────────────────────────┘
           │
┌──────────▼──────────────────────────┐
│  NNTPS Client (GenServer)           │
│  - TLS 1.2/1.3 connection           │
│  - RFC 3977 protocol                │
└──────────┬──────────────────────────┘
           │ NNTPS (Port 563)
┌──────────▼──────────────────────────┐
│  NNTPS Server                       │
│  (news.eternal-september.org)       │
└─────────────────────────────────────┘
```

## Key Files

**Backend:**
- `lib/no_nonsense_nntps/client.ex` - NNTPS protocol client (GenServer)
- `lib/no_nonsense_nntps/client_manager.ex` - Singleton client manager
- `lib/no_nonsense_nntps/api.ex` - HTTP REST API (Plug/Bandit)
- `lib/no_nonsense_nntps.ex` - Application supervisor

**Frontend:**
- `frontend/src/App.res` - Main TEA application
- `frontend/src/Api.res` - HTTP client for backend
- `frontend/src/Types.res` - Type definitions
- `frontend/index.html` - Entry point with styling

## What Works

✅ TLS/SSL connection to NNTPS server (port 563)
✅ RFC 3977 protocol implementation
✅ CAPABILITIES, GROUP, ARTICLE, LIST commands
✅ Multi-line response parsing with dot-stuffing
✅ HTTP API with CORS support
✅ React-based UI with connection management
✅ Article fetching and display
✅ Error handling and status updates

## What's Next (Week 2)

- [ ] Newsgroup browser (list and select groups)
- [ ] Article list view (browse articles in a group)
- [ ] cadre-tea-router integration for navigation
- [ ] Better UI/UX with proper layout
- [ ] Article navigation (next/previous)

## Testing with Public Servers

Public NNTPS servers you can test with:
- `news.eternal-september.org:563` (requires registration)
- `nntp.aioe.org:563` (open access)

Make sure to use valid article Message-IDs from these servers!
