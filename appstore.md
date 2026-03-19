# App Store Connect — TinySQL

## App Information

- **App Name**: TinySQL
- **Subtitle** (30 chars max): A simple PostgreSQL browser
- **Bundle ID**: com.tinysql.app
- **SKU**: tinysql-001
- **Primary Language**: English (U.S.)
- **Category**: Developer Tools
- **Secondary Category**: Productivity
- **Content Rights**: Does not contain third-party content
- **Age Rating**: 4+

## Version 1.0.0

### Description (4000 chars max)

TinySQL is a fast, native PostgreSQL browser for macOS. Connect to a database, browse your tables, and inspect your data — without writing a query. No heavyweight IDEs. No Electron wrappers. Just a clean, native window on your database.

Features:
- Connect to any PostgreSQL server with host, port, database, username, and password
- Sidebar table list from your public schema
- Click a table to see its data instantly
- Sortable columns — click to sort ascending or descending
- Alternating row colors for readability
- NULL values displayed with dimmed styling
- Pagination for large tables (100 rows per page)
- Query time and row count in the status bar
- Connection persistence — remembers your last connection
- Multiple connection support
- Pure Swift implementation — no PostgreSQL drivers or C libraries required
- Light and dark mode — follows your system

Built entirely with native macOS technologies and PostgresNIO for database communication. No Electron. No JVM. Connects directly to your database with zero configuration overhead.

### Keywords (100 chars max, comma-separated)

postgresql,database,sql,browser,table,viewer,developer,postgres,data,query

### What's New (Version 1.0.0)

Initial release.

### Promotional Text (170 chars max, can be updated without review)

A fast, native PostgreSQL browser for macOS. Connect, browse tables, sort data. No drivers, no heavyweight tools. Just your database, one click away.

### Support URL

https://github.com/michellzappa/tinysql/issues

### Marketing URL (optional)

https://github.com/michellzappa/tinysql

### Privacy Policy URL (required)

<!-- You need a privacy policy URL even if the app collects no data. -->
<!-- Example: https://michellzappa.github.io/tinysql/privacy -->

TODO: Create a simple privacy policy page stating the app collects no data.

## Privacy Details

- **Data Collection**: None — the app does not collect or transmit any data
- **Tracking**: No
- **Data Linked to You**: None
- **Data Not Linked to You**: None

## Screenshots (required)

Mac: At least one screenshot at 2880x1800 or 1600x1000 (16-inch Retina)

Recommended screenshots:
1. Table data view with sortable columns
2. Connection dialog
3. Dark mode view with table sidebar
4. Large table with pagination controls

## App Icon

- 1024x1024 PNG (generated from AppIcon.icon assets)
- No transparency, no rounded corners (macOS applies the mask automatically)

## Pricing

- **Price**: Free
- **Availability**: All territories

## Notes for Review

TinySQL is a native macOS PostgreSQL database browser. It connects to user-specified PostgreSQL servers to browse and display table data. It does not collect analytics, does not phone home, and does not require an account. Database credentials are stored locally in user defaults. Network access is used solely for the database connection.
