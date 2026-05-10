## Problem Statement

Currently, songs (`Repertoire::Music`) store their author as a simple string. This prevents rich associations, such as listing all songs by a specific author. Additionally, the URLs for songs use the internal database ID (e.g., `/repertoire/musics/1`), which is not human-readable or SEO-friendly. Users want a more intuitive way to navigate and identify songs.

## Solution

1.  **Introduce `Repertoire::Author` Model**: Create a dedicated model for authors to manage their details and establish a formal relationship with songs.
2.  **Migrate Existing Data**: Convert the current `author` string column in `repertoire_musics` to a foreign key pointing to the new `Author` model.
3.  **Implement Slugs**: Add `slug` columns to both `Repertoire::Author` and `Repertoire::Music` to support human-readable URLs.
4.  **Human-Readable URLs**: Implement a nested routing structure: `/repertoire/musics/:author_slug/:music_slug`.

## User Stories

1.  **[MUST]** As a user, I want to see the author's name as a link on the song page.
2.  **[MUST]** As a user, I want to navigate to a song using a URL like `/repertoire/musics/padre-jonas-abib/vem-espirito-santo`.
3.  **[MUST]** As a user, I want the system to automatically generate a slug for new authors and songs based on their names.
4.  **[MUST]** As the system, I want to ensure that existing songs are correctly associated with their respective authors during the migration.
5.  **[SHOULD]** As a user, I want to view a list of all songs by a specific author by clicking on their name.

## Implementation Decisions

### 1. Models
-   **`Repertoire::Author`**:
    -   Attributes: `name` (string), `slug` (string, indexed, unique).
    -   Associations: `has_many :musics`.
-   **`Repertoire::Music`**:
    -   Attributes: `author_id` (foreign key), `slug` (string, indexed, unique).
    -   Associations: `belongs_to :author`.
    -   Note: The old `author` string column will be removed after the migration.

### 2. Slugs & Parameters
-   We will implement a simple native slugging mechanism.
-   Both models will have a `before_validation` to generate a slug if one doesn't exist, using `name.parameterize` (Author) and `title.parameterize` (Music).
-   `to_param` will be overridden in both models to return the `slug`.

### 3. Routing
-   A custom route will be defined: `get 'musics/:author_slug/:id', to: 'musics#show', as: :author_music`.
-   Note: We will keep `:id` as the parameter name for the music slug to maintain compatibility with standard Rails `find` logic if we use `find_by!(slug: params[:id])`.
-   The standard `resources :musics` will be kept for administrative tasks (index, new, edit) but the `show` action will prioritize the human-readable route.

### 4. Migration Strategy
1.  Create `repertoire_authors` table.
2.  Add `author_id` (null: true) and `slug` to `repertoire_musics`.
3.  Data Migration:
    -   Iterate through `Repertoire::Music`.
    -   For each unique `author` string, create a `Repertoire::Author`.
    -   Update `Repertoire::Music#author_id`.
    -   Generate slugs for all records.
4.  Make `author_id` null: false.
5.  Remove the `author` string column.

## Testing Decisions

### Model Tests
-   Verify slug generation for `Author` and `Music`.
-   Verify uniqueness constraints for slugs.
-   Test associations between `Author` and `Music`.

### Controller Tests
-   Verify that the `show` action works with the new nested slug route.
-   Ensure that old ID-based URLs either redirect to the slug-based URL or continue to work (user preference). *Decision: We will prioritize slugs.*

## Out of Scope
-   Author biographies or photos.
-   Handling slug collisions (e.g., two songs with the same name by the same author). *Initial implementation will assume uniqueness or append a random suffix.*
-   Redirecting old ID URLs (can be added later if needed).

## Further Notes
-   "Padre Jonas Abib" becomes `padre-jonas-abib`.
-   "Vem Espírito Santo" becomes `vem-espirito-santo`.
-   The UI (KeyMutator, etc.) should be updated to use the new route helpers.
