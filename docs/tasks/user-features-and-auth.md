# Tasks: User Side, My Repertoire, and Setlists

## Task 1: Base Auth & Admin Role — 2 points

**Type:** AFK
**Blocked by:** None
**User stories:** 1, 10, 11

### What to build
Implement the core authentication system using Rails 8's native generator. This includes the `User` model, sessions, and basic login/logout UI.
- `User` model with `role` enum (`admin`, `user`).
- Global admin creation via `db:seeds.rb`.
- Auth boilerplate (controllers, views, and `Current` concern).

### Acceptance criteria
- [ ] Users can log in and out.
- [ ] Sidebar shows "Login" when guest, "Logout" when authenticated.
- [ ] `rails db:seed` creates an admin user.

---

## Task 2: Invitation System — 2 points

**Type:** AFK
**Blocked by:** Task 1
**User stories:** 9

### What to build
A system for admins to invite new users. Since we don't have SMTP, the admin generates a link with a token that the user can open to register.
- `Invitation` model: `email`, `token`, `expires_at` (default 24h).
- Admin-only view to generate invitation links.
- Public registration page that only works with a valid, non-expired invitation token.

### Acceptance criteria
- [ ] Admin can generate a link.
- [ ] Link expires after 24 hours.
- [ ] Registering via a valid link creates a `User` and destroys/invalidates the invitation.

---

## Task 3: "My Repertoire" (SavedMusic) — 2 points

**Type:** AFK
**Blocked by:** Task 1
**User stories:** 2, 3

### What to build
The personal library feature. Users can "save" songs from the global library to their personal collection with customizations.
- `SavedMusic` model: `user_id`, `music_id`, `preferred_key`, `remarks`.
- "Add to My Repertoire" button on the music show page.
- "My Repertoire" index page showing all saved songs.

### Acceptance criteria
- [ ] User can save a song with a specific key and text remarks.
- [ ] User can see their list of saved songs.
- [ ] The music page shows if a song is already in the user's repertoire.

---

## Task 4: Setlists CRUD & Music Page Interaction — 2 points

**Type:** AFK
**Blocked by:** Task 1, Task 3
**User stories:** 4

### What to build
Basic CRUD for Setlists (Roteiros) and the ability to start a setlist from a song page.
- `Setlist` model: `user_id`, `name`, `date`, `location`, `setlist_type` (missa, evento, etc.).
- `SetlistItem` model: `setlist_id`, `music_id`, `key`, `position`.
- "Add to Setlist" modal/interaction on the music show page (Actions menu).

### Acceptance criteria
- [ ] User can create, read, update, and delete setlists.
- [ ] From any song, user can click "Add to Setlist" and pick an existing setlist.

---

## Task 5: Mass Templates & Drag-and-Drop Reordering — 3 points

**Type:** HITL
**Blocked by:** Task 4
**User stories:** 5, 6, 7

### What to build
The advanced UI for setlists.
- Logic to pre-populate slots based on `MassPart` when the setlist type is "Missa".
- Drag-and-drop UI (using Turbo/Stimulus) to reorder `SetlistItem` within a setlist.
- Ability to change the `key` of a song inside the setlist without affecting `SavedMusic`.

### Acceptance criteria
- [ ] Creating a "Missa" setlist shows all standard liturgical parts as empty slots.
- [ ] User can reorder any song using drag-and-drop.
- [ ] Changing a key in a setlist persists only for that setlist.

---

## Task 6: Flexible Setlist Filling & Public UID — 2 points

**Type:** AFK
**Blocked by:** Task 5
**User stories:** 6, 8

### What to build
Enhance the setlist editing and sharing.
- "Add Song" to a specific Mass slot: suggest songs with the same `MassPart` by default, but provide a search bar for *all* songs.
- Generate a unique `uid` (random token) for each setlist.
- Public read-only view: `setlists/:uid` accessible without login.

### Acceptance criteria
- [ ] User can add multiple songs to a Mass slot.
- [ ] User can add a "Non-suggested" song to a Mass slot.
- [ ] Anyone with the link can view the setlist details (Public mode).

---

## Task 7: Auth Protection & UX Final Polish — 1 point

**Type:** AFK
**Blocked by:** Task 1
**User stories:** 12

### What to build
Final security and navigation polish.
- Add `before_action :authenticate_user!` to relevant controllers.
- Implement `redirect_to` logic: if a user hits an auth wall, they return to the same page after login.
- Update sidebar to include "My Repertoire" and "My Setlists" links.

### Acceptance criteria
- [ ] Unauthenticated users are redirected to login when trying to access setlists.
- [ ] After login, user is redirected back to their original destination.
