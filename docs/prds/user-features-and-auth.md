# PRD: User Side, My Repertoire, and Setlists

## Problem Statement

Musicians need a way to organize the songs they play, save their preferred musical keys for each song, and create structured setlists (roteiros) for specific events like Masses, which have a specific liturgical flow. Currently, the application is public and read-only for users, lacking personalization and organization tools.

## Solution

Implement a user-side ecosystem including:
1.  **Authentication:** A simple email/password login to protect personal data.
2.  **Meu Repertório (My Repertoire):** A personal library where users save songs with their preferred key and personal remarks.
3.  **Roteiros (Setlists):** A tool to create event-specific song lists. For Masses, a fixed template based on liturgical parts will be provided. Setlists can be shared via a public UID for band members to follow.
4.  **Admin Role:** To manage the global library and invite new users via time-limited links.

## User Stories

1.  As a musician, I want to log in with my email and password so I can access my personalized library.
2.  As a musician, I want to add a song to "Meu Repertório" with my preferred key so I don't have to transpose it every time.
3.  As a musician, I want to add remarks to a saved song so I can remember specific performance details (e.g., "use capo on 2nd fret").
4.  As a musician, I want to create a "Roteiro" for a specific date and location so I can organize my upcoming performances.
5.  As a musician, I want to choose a "Missa" template for my Roteiro so that I have a predefined structure of Mass parts to fill.
6.  As a musician, I want to add multiple songs to a single Mass part in a Roteiro so I can handle complex liturgical moments.
7.  As a musician, I want to change the key of a song within a specific Roteiro without affecting my global preferred key in "Meu Repertório".
8.  As a musician, I want to share a Roteiro via a unique link (UID) so my bandmates can see the setlist without needing an account.
9.  As an admin, I want to generate a 24-hour invitation link so I can safely add new users to the platform.
10. As an admin, I want to maintain control over the global music and author database to ensure data quality.
11. As a user, I want to see a "Login" button in the sidebar when I'm not authenticated so I can easily access my account.
12. As a user, I want to be redirected back to my intended page after logging in if I was intercepted by an auth wall.

## Implementation Decisions

- **Auth:** Use Rails 8 built-in `authentication` generator.
- **Models:**
    - `User`: `email`, `password_digest`, `role` (admin/user).
    - `Invitation`: `email`, `token`, `expires_at`.
    - `SavedMusic` (Meu Repertório): `user_id`, `music_id`, `preferred_key`, `remarks`.
    - `Setlist` (Roteiro): `user_id`, `name`, `date`, `location`, `setlist_type` (missa, evento, etc.), `uid` (random token).
    - `SetlistItem`: `setlist_id`, `music_id`, `key`, `position`, `mass_part_id` (optional, for Missa type).
- **Modules:**
    - `AuthenticationModule`: Handles sessions and access control.
    - `SetlistTemplateEngine`: Logic to generate the initial structure for "Missa" type setlists.
- **UI:**
    - Sidebar update for Login/Logout and "Meu Repertório" link.
    - "Add to My Repertoire" button on the music show page.
    - Public read-only view for Setlists using the `uid`.

## Testing Decisions

- **Request Specs:** Test the authentication flow and redirection logic.
- **Model Specs:** Validate invitation expiration and Setlist UID generation.
- **System Specs:** Verify the "Missa" template pre-filling and song addition within setlists.
- **Privacy:** Ensure one user cannot see or edit another user's "Meu Repertório" or private Setlists.

## Out of Scope

- Password reset via email (no SMTP).
- Social login (Google, Facebook).
- Multi-user collaboration on the same setlist (only public read-only sharing).
- File uploads for sheet music or slides (future).

## Further Notes

- Invitation links expire in 24 hours.
- Mass parts are already defined in the database and should be used to build the template slots.
