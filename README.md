# deneme - Notes App (MVVM + Layered Architecture)

This project is structured as a production-ready UIKit app with MVVM and clean layering.

## Architecture

- `Core`: app lifecycle, dependency container, theme, persistence setup
- `Domain`: business models, protocols, use-cases, domain errors
- `Data`: local/remote data sources, repository implementations, preferences store
- `Presentation`: screens, view models, reusable views

## Folder Structure

- `deneme/Core`
- `deneme/Domain`
- `deneme/Data`
- `deneme/Presentation`

## Current Capabilities

- Notes list with sorting (created date, updated date, A-Z)
- Swipe to delete and multi-select batch delete
- Single editor screen for create/update
- Theme settings (System/Light/Dark)
- Core Data local persistence

## Storage Strategy (Future-Ready)

The app is designed for multiple storage backends via repository routing:

- `local` -> `CoreDataNotesDataSource`
- `firebase` -> `FirebaseNotesDataSourceStub` (placeholder)

`NoteStorageOption` is already part of the domain and editor flow, so Firebase can be enabled later without breaking the presentation layer.
