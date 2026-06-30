# 7. Structured Discord Rendering

Date: 2026-06-30

## Status

Accepted

## Context

With Antigravity 2.0, the chat UI changed significantly. It now produces structured DOM elements like `.plan-step`, `.file-chip`, and `.action-btn` instead of just raw Markdown text. The previous fallback text extraction in `ResponseMonitor` flattened these UI elements into confusing or truncated text streams, which resulted in a degraded user experience when interacting through Discord.

Furthermore, Discord replies and attachments (both image and text) needed to be mapped back correctly to Antigravity's chat context.

## Decision

We have updated LazyGravity to use a structured response rendering pipeline:

1. **DOM Extraction (`assistantDomExtractor.ts`)**: We maintain and expand this specific extractor as the contract for Antigravity 2.0. It queries the DOM for cards, file chips, action buttons, and citations.
2. **Discord Renderer (`discordResponseRenderer.ts`)**: We introduced a renderer that takes the structured data (the `ClassifyResult`) and produces native Discord components (Embeds for plan cards/file changes, ActionRows for buttons).
3. **End-to-End Pipeline**: `sendPromptToAntigravity` in `bot/index.ts` was updated to consume these structured classification results and dispatch them as rich Discord messages, rather than using the legacy text diffing for the final output.
4. **Context Injection**:
   - Replied-to Discord messages are now fetched and prepended to the prompt text as context.
   - Text attachments (under 50KB) are fetched and their contents appended directly into the prompt text before sending to Antigravity.
   - Image attachments use the existing Antigravity upload pipeline.

## Consequences

- Discord outputs for Antigravity 2.0 are now visually rich, structured, and easy to read.
- We rely on specific DOM class names (`.assistant-body`, `.file-chip`, `.action-btn`, etc.), which means changes to the Antigravity UI might require corresponding updates to `assistantDomExtractor.ts`.
- The Discord bot requires the `MessageContent` intent (which it already has) to fetch text attachments and read replied-to message content.
