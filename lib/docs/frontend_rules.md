# Frontend Responsibilities & Boundaries

## Core Principles

1.  **Display State, Don't Calculate It**: The UI should only reflect the current state provided by the State Management layer. It should never attempt to predict or calculate the next state (e.g., "song position should be X because I clicked play 5 seconds ago").
2.  **Intent Over Action**: The UI sends "User Intents" (e.g., `UserClickedPlay`), not direct commands (e.g., `AudioPlayer.play()`). The logic layer handles the execution and updates the state.
3.  **Responsiveness**: The UI must react immediately to state changes, but user actions can have optimistic updates ONLY if visually distinct (e.g., "Requesting to play...").

## strict "DO NOTs"

-   **DO NOT** resolve merge conflicts in the UI.
-   **DO NOT** maintain a separate "source of truth" in Widgets.
-   **DO NOT** perform complex data validation in the View (basic form validation is okay).
-   **DO NOT** directly call backend APIs from Widgets. Use Repositories/Providers.

## State Management (Riverpod)

-   **Providers**: formatting and simple derivations.
-   **Notifiers**: Handling user intents and updating state.
-   **Repositories**: Data fetching and strict "backend" mocking.

## Navigation

-   Navigation is a side-effect of state change.
-   Use `AuthGuard` and `PairingGuard` to determine the active screen.
-   Avoid `push()`/`pop()` for flow-based navigation; use `go()` to deterministic routes.
