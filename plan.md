# InstantNote Memo App Plan

## 1. Vision
- Deliver a HarmonyOS ArkTS application that lets students capture class moments (typed notes, photos, audio) and automatically organize them into a unified timeline.
- Provide AI assistance by converting speech to text and generating multimodal summaries that combine photos, transcripts, and user notes.

## 2. Key Personas & Needs
| Persona | Needs |
| --- | --- |
| Student in lectures | Quickly capture text + media without context switching, automatically timestamped and ordered. |
| Reviewer after class | Browse structured memo, search by topic/time, read concise AI summary, edit final note. |
| Offline user | Core note-taking must work without network; AI features can queue requests until online. |

## 3. Functional Requirements
1. **Note Management**
   - Create, edit, and delete memos; support sections/blocks ordered by timestamp.
   - Tag notes with course, topic, and location metadata.
2. **Media Capture & Alignment**
   - Capture photos in-app; timestamp and insert near the relevant text block automatically.
   - Attach existing gallery images with manual placement.
3. **Audio Capture & Speech-to-Text**
   - Record audio segments while taking notes.
   - Transcribe speech locally (if available) or via cloud API; display alongside audio clip.
4. **Multimodal Summaries**
   - Send selected memo context (text, photo references, transcript) to LLM API.
   - Render summary blocks; user can regenerate/edit/save.
5. **Synchronization & Storage**
   - Persist memos locally (ArkTS DataAbility / Preferences / relational store).
   - Optional cloud sync (future phase) via backend or third-party services.
6. **Search & Organization**
   - List memos with filters (course, date, keyword).
   - In-note search to jump to text/media timestamps.

## 4. Non-Functional Requirements
- Responsive ArkTS UI optimized for phone/tablet split-screen.
- Offline-first for note editing; graceful degradation for AI features.
- Data privacy: store media securely, encrypt summaries/transcripts at rest when possible.
- Modular architecture enabling future addition of handwriting/PDF import.

## 5. System Architecture Overview
```
┌────────────┐    ┌────────────────┐    ┌────────────────┐
│ArkTS UI    │ -> │Note Domain svc │ -> │Local Data Store│
│(pages/components)   │    │(state mgmt + domain logic)│    │(LiteDB/Preferences)│
└─────┬──────┘    └────────┬──────┘    └────────┬──────┘
      │                    │                   │
      │ capture events     │ persist/query     │
      ▼                    ▼                   ▼
┌────────────┐    ┌────────────────┐    ┌────────────────┐
│Media svc   │    │Audio svc       │    │AI Gateway svc  │
│(camera/gallery)││(record/transcribe)││(speech & summary APIs)│
└────────────┘    └────────────────┘    └────────────────┘
```

- **ArkTS UI Layer**: `EntryAbility` hosts main router, pages for memo list, memo editor, capture overlays, summary view. Uses `@State`/`@Observed` for reactive updates.
- **State/Domain Layer**: Shared store (e.g., `AppStorage` or custom store) encapsulates memo entities (text blocks, media blocks, audio blocks, summaries).
- **Data Layer**: HarmonyOS DataAbility or relational database (e.g., RDB) for structured data; media stored in sandboxed file system with references in DB.
- **Media Service**: Wraps camera kit APIs to capture photos + metadata; posts events to state layer to insert placeholder block while upload/transcode completes.
- **Audio Service**: Handles recording sessions, chunk upload/transcription, attaches transcript text block referencing audio file.
- **AI Gateway**: Abstracted provider (local plugin, cloud HTTP). Queues requests if offline; stores job status for UI binding.

## 6. Data Model Draft
- `Memo`: id, title, courseId, createdAt, updatedAt, tags[], summaryId, blocks[]
- `Block` (union):
  - `TextBlock`: id, memoId, position, content, createdAt.
  - `ImageBlock`: id, memoId, position, fileUri, capturedAt, caption.
  - `AudioBlock`: id, memoId, position, fileUri, duration, transcriptId.
  - `SummaryBlock`: id, memoId, aiJobId, content, createdAt, status.
- `Transcript`: id, audioBlockId, text, confidence, source.
- `AIJob`: id, type (`S2T`, `SUMMARY`), payload metadata, status, resultRef, error.

## 7. MVP Scope vs Future Enhancements
- **MVP**
  1. Basic memo CRUD with text blocks.
  2. In-app camera capture with auto-insert + manual reorder.
  3. Audio recording + cloud speech-to-text integration.
  4. Manual “Generate Summary” using remote LLM API.
  5. Local persistence only.
- **Future**
  - Collaborative sync, multi-device account.
  - Handwriting recognition, PDF/slide import.
  - Smart recommendations (e.g., highlight key terms).
  - Privacy controls (per-note encryption, shareable exports).

## 8. Implementation Roadmap
1. **Foundation (Week 1-2)**
   - Set up ArkTS project structure, navigation, shared state container.
   - Implement memo list/detail UI with local dummy data.
2. **Persistence Layer (Week 2)**
   - Introduce DataAbility + entity mapping.
   - Wire memo CRUD to storage; add unit tests for repositories.
3. **Media Integration (Week 3)**
   - Implement camera capture flow; store image files + metadata.
   - Add block ordering UI (drag/drop or move controls).
4. **Audio & Transcription (Week 4)**
   - Build recorder component, chunk storage.
   - Integrate speech API (configurable endpoint/keys), show transcript block.
5. **AI Summary (Week 5)**
   - Create AI Gateway abstraction.
   - Implement summary generation UI with status, error handling.
6. **Polish & Offline Handling (Week 6)**
   - Add search/filter views, caching, network awareness.
   - QA, performance tuning, prepare beta release.

## 9. Open Questions
1. Target languages/localization requirements?
2. Preferred cloud provider / LLM endpoint (Huawei, OpenAI proxy, etc.)?
3. Do we need enterprise-grade authentication/sync now or can it wait?
4. Should summaries be editable inline or stored as read-only blocks?
5. Any hardware constraints (e.g., must run on wearable/tablet variants)?

