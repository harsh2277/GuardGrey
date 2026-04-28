# GuardGrey

GuardGrey is a Flutter application with Firebase-backed admin, client, site,
attendance, and notifications workflows.

## Project Structure

```text
lib/
  core/
    theme/                 Shared color, typography, and theme setup
  modules/
    admin/
      models/              Branch, site, client, manager, visit, attendance models
      screens/             Admin/auth/profile/site/branch flows
      services/            Firestore and location services
      widgets/             Reusable admin UI widgets
    notifications/
      models/              Notification entities
      services/            Push/local notification setup and persistence
  routes/                  Route registration and navigation guards
  screens/                 Main app sections wired into bottom navigation
  widgets/                 Cross-feature shared widgets
  main.dart                App bootstrap
```

## Supporting Directories

```text
assets/images/             App image assets
docs/                      Project documentation
functions/                 Firebase Cloud Functions
android/ ios/ web/         Flutter platform targets
linux/ macos/ windows/     Desktop platform targets
```

## Notes

- Generated folders such as `build/`, `.dart_tool/`, and platform `ephemeral/`
  directories are local artifacts and should stay out of version control.
- The active app structure currently uses both `lib/modules/...` and
  `lib/screens/...`; they are both part of the running app.
