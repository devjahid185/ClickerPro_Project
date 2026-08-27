# Google Sheets Auto Sync Setup

Graphy7 can write booking and payment activity directly to a Google Sheet from the Laravel backend. The mobile app does not need to open Google Sheets, and users do not need to press Save anywhere.

## What Gets Synced

The backend creates and styles these tabs automatically if the service account has edit access:

- `Bookings`: booking created, booking updated, and booking status updated rows.
- `Payments`: payment created, payment updated, and payment deleted rows.

Each tab gets a bold dark header row, frozen header, filters, and auto-sized columns so the sheet is cleaner for printing.

## Setup

1. Create a Google Sheet, for example `Graphy7 Studio Ledger`.
2. In Google Cloud Console, enable `Google Sheets API`.
3. Create a service account and download its JSON key.
4. Upload the JSON key outside public web access, for example:

```env
/home/your-user/clickerpro/laravel_backend/storage/google-sheets-key.json
```

5. Share the Google Sheet with the service account email as `Editor`.
6. Add these values to Laravel `.env`:

```env
GOOGLE_SHEETS_CREDENTIALS=/home/your-user/clickerpro/laravel_backend/storage/google-sheets-key.json
GOOGLE_SHEETS_ID=your_spreadsheet_id_from_the_sheet_url
GOOGLE_SHEETS_BOOKINGS_TAB=Bookings
GOOGLE_SHEETS_PAYMENTS_TAB=Payments
```

`GOOGLE_SHEETS_BOOKINGS_TAB` and `GOOGLE_SHEETS_PAYMENTS_TAB` are optional. If omitted, the defaults are `Bookings` and `Payments`.

7. Clear Laravel config cache:

```bash
php artisan config:clear
```

## Test

Create or update a booking from the app, then record a payment. The rows should appear in the Google Sheet automatically.

If nothing appears, check Laravel logs:

```bash
tail -50 storage/logs/laravel.log
```

Search for `GoogleSheets`. Common causes are an incorrect JSON path, wrong spreadsheet id, Google Sheets API not enabled, or the sheet not shared with the service account email.

## Safety

Google Sheets sync is fail-safe. If Google is down or the credentials are wrong, bookings and payments still save normally in the app/database; only the sheet row is skipped and a warning is logged.
