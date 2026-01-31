# Seam Analysis: Week 1 & 2 Integration Points

**Purpose:** Verify all integration points between backend (Week 1) and frontend (Week 2) are properly connected.

## 1. API Endpoint Seams (Backend ↔ Frontend)

### Seam 1.1: Connection Endpoint
**Backend:** `POST /api/connect`
**Frontend:** `Api.connect(~host, ~port, ~onSuccess, ~onFailure)`

**Contract:**
```
Request:  { "host": string, "port": number }
Response: { "status": "connected", "host": string, "port": number }
```

**Verification:**
- [ ] Backend accepts POST with JSON body
- [ ] Frontend sends correct Content-Type header
- [ ] Success callback fires on 200 OK
- [ ] Failure callback fires on error with message

---

### Seam 1.2: Groups List Endpoint
**Backend:** `GET /api/groups`
**Frontend:** `Api.fetchGroups(~onSuccess, ~onFailure)`

**Contract:**
```
Response: {
  "groups": [
    { "name": string, "high": int, "low": int, "status": string }
  ]
}
```

**Verification:**
- [ ] Backend returns array of groups
- [ ] Frontend parses groups correctly
- [ ] Empty groups array handled gracefully
- [ ] Large groups list (10,000+) doesn't crash

---

### Seam 1.3: Group Selection Endpoint
**Backend:** `GET /api/groups/:name`
**Frontend:** `Api.selectGroup(~groupName, ~onSuccess, ~onFailure)`

**Contract:**
```
Response: {
  "name": string,
  "count": int,
  "first": int,
  "last": int
}
```

**Verification:**
- [ ] Backend returns group info
- [ ] Frontend receives all fields
- [ ] Group name with special chars encoded properly
- [ ] 404 handled for non-existent groups

---

### Seam 1.4: Articles List Endpoint
**Backend:** `GET /api/groups/:name/articles?first=X&last=Y`
**Frontend:** `Api.fetchArticles(~groupName, ~first?, ~last?, ~onSuccess, ~onFailure)`

**Contract:**
```
Response: {
  "articles": [
    {
      "number": int,
      "subject": string,
      "from": string,
      "date": string,
      "message_id": string
    }
  ]
}
```

**Verification:**
- [ ] Backend fetches last 100 articles when range specified
- [ ] Frontend sends first/last query params correctly
- [ ] Empty articles array handled
- [ ] message_id vs messageId field name mapping works

---

### Seam 1.5: Article Fetch Endpoint
**Backend:** `GET /api/articles/:id`
**Frontend:** `Api.fetchArticle(~articleId, ~onSuccess, ~onFailure)`

**Contract:**
```
Response: {
  "headers": { "subject": string, "from": string, ... },
  "body": string
}
```

**Verification:**
- [ ] Backend returns headers as object
- [ ] Frontend receives headers as Dict.t<string>
- [ ] Body with special characters preserved
- [ ] Message-ID URL encoding works

---

## 2. Type Mapping Seams (Elixir ↔ ReScript)

### Seam 2.1: Group Info Type
**Elixir:** `%{name: String.t(), high: integer(), low: integer(), status: String.t()}`
**ReScript:** `type groupInfo = { name: string, high: int, low: int, status: string }`

**Verification:**
- [ ] JSON serialization matches
- [ ] All fields present
- [ ] Types compatible (string ↔ string, integer ↔ int)

---

### Seam 2.2: Article Overview Type
**Elixir:** `%{number: integer(), subject: String.t(), from: String.t(), date: String.t(), message_id: String.t()}`
**ReScript:** `type articleOverview = { number: int, subject: string, from: string, date: string, messageId: string }`

**⚠️ POTENTIAL ISSUE:** Field name mismatch: `message_id` (Elixir) vs `messageId` (ReScript)

**Verification:**
- [ ] Field name mapping works (message_id → messageId)
- [ ] All fields populated
- [ ] Date string format preserved

---

### Seam 2.3: Article Type
**Elixir:** `%{headers: map(), body: String.t()}`
**ReScript:** `type article = { headers: Dict.t<string>, body: string }`

**Verification:**
- [ ] Headers map converts to Dict.t properly
- [ ] Nested header values all strings
- [ ] Body preserves whitespace/formatting

---

## 3. State Management Seams (Router ↔ App)

### Seam 3.1: Route Changes Trigger API Calls
**Router:** `useRouter()` returns `(route, push)`
**App:** `React.useEffect` on `currentRoute` change

**Flow:**
```
Router.push(Groups)
  → useEffect detects route change
  → dispatch(FetchGroups)
  → Api.fetchGroups()
```

**Verification:**
- [ ] Route changes detected by useEffect
- [ ] Dependency array includes currentRoute
- [ ] API calls only fire once per route change
- [ ] No infinite loops

---

### Seam 3.2: Navigation State Updates
**Router:** Browser history API (`pushState`, `popstate`)
**App:** Model state (selectedGroup, articles, article)

**Verification:**
- [ ] Back button clears article state
- [ ] Forward button restores state
- [ ] URL changes reflected in model
- [ ] Model changes reflected in UI

---

## 4. Error Handling Seams

### Seam 4.1: Network Errors
**Backend:** Connection failures, timeouts
**Frontend:** `onFailure` callbacks with error messages

**Verification:**
- [ ] Backend offline → "Network error" shown
- [ ] Timeout → Error displayed
- [ ] 404/500 → HTTP status shown
- [ ] Error cleared on next successful request

---

### Seam 4.2: NNTPS Protocol Errors
**Backend:** NNTPS error codes (4xx, 5xx responses)
**Frontend:** Generic error display

**Verification:**
- [ ] Invalid group name → Error message
- [ ] Invalid article ID → Error message
- [ ] Server rejection → Error message
- [ ] Connection errors → Reconnect possible

---

## 5. Data Flow Seams (End-to-End)

### Flow 1: Connection → Groups → Articles → Article

```
1. User enters host/port → click Connect
2. Frontend: Api.connect() → POST /api/connect
3. Backend: ClientManager.connect() → Client GenServer → NNTPS TLS handshake
4. Frontend: onSuccess() → Router.push(Groups)
5. Frontend: useEffect detects Groups route → Api.fetchGroups()
6. Backend: Client.list_groups() → NNTPS "LIST ACTIVE" command
7. Frontend: onSuccess(groups) → display NewsgroupList
8. User clicks group → Router.push(GroupView(name))
9. Frontend: useEffect detects GroupView → Api.selectGroup() + Api.fetchArticles()
10. Backend: Client.select_group() → NNTPS "GROUP name"
11. Backend: Client.list_articles() → NNTPS "OVER first-last"
12. Frontend: onSuccess(articles) → display ArticleList
13. User clicks article → Router.push(ArticleView(group, msgId))
14. Frontend: useEffect detects ArticleView → Api.fetchArticle()
15. Backend: Client.fetch_article() → NNTPS "ARTICLE <msg-id>"
16. Frontend: onSuccess(article) → display article with headers/body
```

**Verification:**
- [ ] Complete flow works end-to-end
- [ ] Each step triggers next correctly
- [ ] Loading states shown during async
- [ ] Errors at any step don't break flow

---

## 6. CORS Seam

**Backend:** `CORSPlug` with origins `["http://localhost:8000"]`
**Frontend:** Fetch from `http://localhost:4000`

**Verification:**
- [ ] OPTIONS preflight succeeds
- [ ] CORS headers present in responses
- [ ] No browser console CORS errors
- [ ] All HTTP methods allowed (GET, POST)

---

## 7. Critical Seams to Test

### Priority 1: Connection Flow
1. Start backend: `iex -S mix`
2. Start frontend: `deno task serve`
3. Navigate to `http://localhost:8000`
4. Enter server: `news.eternal-september.org:563`
5. Click Connect
6. **Expected:** Status changes to "Connected", route changes to `/groups`

---

### Priority 2: Groups List
1. After connection successful
2. **Expected:** Groups list loads with 10,000+ groups
3. Type in search box
4. **Expected:** Filter works instantly
5. Click any group
6. **Expected:** Route changes to `/groups/[name]`

---

### Priority 3: Article List
1. After selecting group
2. **Expected:** Article list shows last 100 articles
3. Table shows #, Subject, From, Date
4. Click any article
5. **Expected:** Route changes to `/groups/[name]/article/[id]`

---

### Priority 4: Article View
1. After clicking article
2. **Expected:** Article headers and body display
3. Headers formatted as definition list
4. Body preserves whitespace
5. Click "Back to Articles"
6. **Expected:** Route changes back, article list still loaded

---

## 8. Known Potential Issues

### Issue 1: message_id Field Name
**Problem:** Backend uses `message_id`, frontend expects `messageId`
**Status:** ⚠️ VERIFY - JavaScript might auto-convert or we need manual mapping
**Fix:** Check if Object.magic preserves field names or add explicit mapping

### Issue 2: Empty Groups/Articles Arrays
**Problem:** What if server has no groups or group has no articles?
**Status:** ✅ HANDLED - Frontend shows "No results" message
**Fix:** Already implemented in NewsgroupList and ArticleList

### Issue 3: Large Payload Performance
**Problem:** 10,000+ groups might be slow to render
**Status:** ⚠️ TEST - Need to verify with real server
**Fix:** May need pagination or virtualized list

### Issue 4: URL Encoding Special Characters
**Problem:** Group names with special chars might break URLs
**Status:** ⚠️ TEST - Need to verify encoding/decoding
**Fix:** Use encodeURIComponent in Router if needed

---

## 9. Testing Checklist

### Backend Tests
- [ ] `mix compile` - No warnings
- [ ] Start server: `iex -S mix` - Boots successfully
- [ ] Manual API test: `curl http://localhost:4000/api/health` - Returns OK

### Frontend Tests
- [ ] `npm run build` - Compiles successfully
- [ ] `deno task serve` - Server starts on port 8000
- [ ] Browser console - No JavaScript errors on load

### Integration Tests
- [ ] Connect to public NNTPS server
- [ ] Browse groups list
- [ ] Select group and view articles
- [ ] Read full article
- [ ] Browser back/forward works
- [ ] Refresh page maintains state (URL-based)

---

## 10. Next Steps

After seam verification:
1. Fix any identified issues
2. Add error handling for edge cases
3. Performance test with large datasets
4. Add loading indicators for slow operations
5. Proceed to Week 3 (Security Integration)
