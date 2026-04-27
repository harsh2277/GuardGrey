# GuardGrey Firestore Schema

This schema is inferred from the current Flutter UI, forms, list cards, detail pages, notification repository, and Cloud Functions.

## Collections

### `branches`

Derived from:
- `AddBranchScreen`
- `BranchesScreen`
- `BranchDetailScreen`

Fields:
- `name` `string` required
- `city` `string` required
- `address` `string` required
- `latitude` `double?`
- `longitude` `double?`
- `siteIds` `List<String>` required
- `createdAt` `Timestamp` required
- `updatedAt` `Timestamp` required

UI usage:
- Search by `name`, `city`, `address`
- Detail page shows `name`, `city`, `address`, `siteIds.length`, timestamps

### `clients`

Derived from:
- `AddClientScreen`
- `ClientsScreen`
- `ClientDetailScreen`

Fields:
- `name` `string` required
- `email` `string` required
- `phone` `string` required
- `branchId` `string` required
- `siteIds` `List<String>` required
- `createdAt` `Timestamp` required
- `updatedAt` `Timestamp` required

UI usage:
- Search by `name`, `email`, `phone`, branch
- Detail page shows `name`, `email`, `phone`, branch

### `managers`

Derived from:
- `AddManagerScreen`
- `ManagersListScreen`
- `ManagerDetailScreen`

Fields:
- `name` `string` required
- `email` `string` required
- `phone` `string` required
- `siteIds` `List<String>` required
- `createdAt` `Timestamp` required
- `updatedAt` `Timestamp` required

UI usage:
- Search by `name`, `email`, `phone`
- Detail page shows `name`, `email`, `phone`, assigned sites

### `sites`

Derived from:
- `AddSiteScreen`
- `SitesScreen`
- `SiteDetailScreen`

Fields:
- `name` `string` required
- `clientId` `string` required
- `branchId` `string` required
- `managerId` `string` required
- `location` `string` required
- `address` `string` required
- `latitude` `double?`
- `longitude` `double?`
- `description` `string`
- `isActive` `bool` required
- `createdAt` `Timestamp` required
- `updatedAt` `Timestamp` required

UI usage:
- Search by `name`, `branch`, `client`, `manager`, `location`
- Detail page shows `clientId`, `branchId`, `managerId`, address, description, timestamps

### `attendance`

Derived from:
- `AttendanceScreen`
- `AttendanceTable`
- `functions/index.js` `onAttendanceWritten`

Fields:
- `managerId` `string` required
- `managerName` `string` required
- `siteId` `string?`
- `siteName` `string?`
- `status` `string` required
- `date` `Timestamp` required
- `checkInAt` `Timestamp?`
- `checkOutAt` `Timestamp?`
- `updatedAt` `Timestamp` required

UI usage:
- Search by `managerName`, `status`, `date`, check-in, check-out
- Notification trigger reads `managerName`, `siteName`, `status`, `checkInAt`, `checkOutAt`

### `site_visits`

Derived from:
- `SiteDetailScreen`
- `VisitTable`
- `functions/index.js` `onSiteVisitCreated`

Fields:
- `siteId` `string` required
- `siteName` `string` required
- `managerId` `string` required
- `managerName` `string` required
- `date` `Timestamp` required
- `day` `string` required
- `timeLabel` `string` required
- `status` `string` required
- `notes` `string`
- `createdAt` `Timestamp` required

UI usage:
- Search by `managerName`, `date`, `day`, `timeLabel`, `status`, `notes`
- Site detail visit history is a direct query candidate on `siteId`

### `notifications`

Derived from:
- `NotificationsScreen`
- `NotificationRepository`
- Cloud Functions that write notifications

Fields:
- `title` `string` required
- `message` `string` required
- `type` `string` required
- `createdAt` `Timestamp` required
- `isRead` `bool` required
- `readAt` `Timestamp?`
- `sourceCollection` `string?`
- `sourceId` `string?`

UI usage:
- Ordered by `createdAt desc`
- Unread badge counts depend on `isRead == false`

### `admin_notification_tokens`

Derived from:
- `NotificationRepository.upsertAdminToken`
- push notification registration flow

Fields:
- `token` `string` required
- `role` `string` required
- `platform` `string` required
- `notificationsEnabled` `bool` required
- `updatedAt` `Timestamp` required

Note:
- This is an operational delivery collection, not a user-facing module list screen
- The seed script intentionally does not create fake device tokens

## Relationships

- One `branch` has many `sites`
- One `client` has one primary `branch`
- One `client` can be assigned many `sites`
- One `manager` can supervise many `sites`
- One `site` belongs to one `branch`
- One `site` belongs to one `client`
- One `site` has one primary `manager`
- One `site` has many `site_visits`
- One `manager` has many `attendance` records
- `notifications` can point back to `attendance` or `site_visits`

## Seeding

Ready-to-use seed logic is implemented in:

- `lib/modules/admin/services/firestore_seed_service.dart`

Primary entry point:

- `seedDatabase({FirebaseFirestore? firestore, bool clearExisting = false})`

What it seeds:

- `branches`
- `clients`
- `managers`
- `sites`
- `attendance`
- `site_visits`
- `notifications`

What it does not seed:

- `admin_notification_tokens`

Reason:

- Avoid inserting fake FCM tokens into the push delivery pipeline.
