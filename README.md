# hotel

## Local build and deployment

This project is a Java 17, Java EE 8 (`javax.*`) servlet application. It targets
Tomcat 9 and is packaged as a WAR with Maven:

```powershell
mvn clean package
```

Deploy `target/hotel.war` to Tomcat 9. Tomcat 10+ uses `jakarta.*` and is not
compatible with this source without a migration. Maven downloads the Servlet API
and MySQL driver; do not copy local IDE output folders into a live Tomcat webapp.

On Windows, `./run-local.ps1` builds the WAR, deploys it into a project-local
Tomcat base, and opens `http://localhost:8080/hotel/`. It uses the installed
Tomcat 9 path shown in the script by default, prompts for the local MySQL user
and password if they are not already set in the current PowerShell session, and
keeps Tomcat logs in a separate console. You can pass `-TomcatHome` if Tomcat 9
is installed elsewhere. The project-local Tomcat files are ignored by Git.

## Database setup and owner account

`database/hotel.sql` is a development/demo first-time setup script. It no longer
drops an existing database. It creates sample data, and all sample user password
hashes are random and unusable. Do not use its sample records for a live property.
Run it only against a new, empty development database. Its table creation and
seed inserts are intentionally not a repeatable migration and will fail or
collide with records if rerun against an existing database.
Back up the database and use reviewed migrations for changes to an existing live
database.

If your existing local database still contains the old seed password placeholder,
review and run `database/migrations/20260925_secure_seed_passwords.sql` once. It
only changes the bundled seed rows that still have that exact placeholder.

To provision the first owner, register the owner's account, then use a secured
database administrator session to promote that exact account:

```sql
UPDATE grand_horizon.users
SET role = 'admin'
WHERE email = 'owner@example.com' AND role = 'guest';
```

Replace the example email with the registered owner address and confirm exactly
one row changed. Do not expose database administrator credentials to the
application. Configure the app's separate database account with only the
required runtime privileges.

## Database configuration

In production, `DBConnection` uses a Tomcat-managed pooled JNDI data source named
`java:comp/env/jdbc/HotelDB`. Configure that resource in the Tomcat deployment
with the app's restricted database account, connection limits, validation query,
and secrets supplied by the host. Install the MySQL Connector/J driver where
Tomcat's data-source pool can load it. The application also declares the JNDI
resource reference in `web/WEB-INF/web.xml`.

For local development, set `HOTEL_DB_URL` to select the environment-based
DriverManager connection path. When it is absent, the application uses the JNDI
data source if configured, then falls back to these environment variables:

- `HOTEL_DB_URL` — MySQL JDBC URL for the `grand_horizon` database
- `HOTEL_DB_USER` — database account with only the permissions the app needs
- `HOTEL_DB_PASSWORD` — that account's password
- `HOTEL_TIME_ZONE` — hotel business time zone used for report date ranges (defaults to `Asia/Kolkata`)

The booking-expiry scheduler starts with the web application and obtains its
connections through `DBConnection`, so it supports either this environment
configuration or the Tomcat JNDI data source. In a multi-instance deployment,
the cleanup operation is safe to run on each instance, but a single scheduled
job is preferable to reduce duplicate work.

Use a dedicated database account and a TLS JDBC URL, for example:

```text
jdbc:mysql://db.example.com:3306/grand_horizon?sslMode=VERIFY_IDENTITY&serverTimezone=Asia/Kolkata&useUnicode=true&characterEncoding=UTF-8
```

Set MySQL/JDBC `serverTimezone` to the same business time zone used by
`HOTEL_TIME_ZONE`, so timestamp event dates and the report date filters agree.

Do not put real credentials in this file, source code, or committed IDE configuration.

## Razorpay configuration

Set `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` in the servlet container or
hosting platform environment. Use a matching key pair from the same Razorpay
mode. The key ID is public and is used by Checkout; the secret stays on the
server for order creation and signature verification. Payment is disabled when
the key ID is missing or invalid, and server payment operations fail closed if
either credential is missing.

Configure the Razorpay webhook URL as `https://your-domain/payment-webhook`
(include the app context path if deployed under one), subscribe to
`payment.captured`, and store its webhook signing secret as
`RAZORPAY_WEBHOOK_SECRET`. Webhook signatures are checked against the raw request
body. Test this with provider test mode before switching to live keys.

## Password reset email

Set `HOTEL_PUBLIC_BASE_URL` to the canonical public HTTPS origin and context
path used by the application (for example `https://grandhorizon.in/hotel`).
Reset links use this configured value and do not trust the inbound Host header.
Set `HOTEL_SMTP_USER` and `HOTEL_SMTP_PASSWORD` in the hosting environment.
The default mail server is Gmail on port 587 with required STARTTLS. For another
provider, set `HOTEL_SMTP_HOST` and `HOTEL_SMTP_PORT`. `HOTEL_SMTP_FROM` and
`HOTEL_SMTP_FROM_NAME` optionally control the sender shown to recipients. Keep
all mail credentials in deployment secrets, not in source control.

Reset tokens are stored as SHA-256 digests. The existing `token` column remains
64 characters wide, so no table alteration is needed. After deploying this
change, previously issued reset links will no longer work; ask users to request
a fresh link.

Password reset requests are throttled per source address and normalized email
within each application instance. Configure an edge or shared rate limiter too
when running multiple application instances.

## Before public launch

- Configure HTTPS at the load balancer or Tomcat connector, then configure the
  Tomcat session cookie as `Secure` and `HttpOnly`. If TLS terminates at a proxy,
  configure Tomcat's proxy scheme/secure settings so the application sees the
  original HTTPS request. Verify the `JSESSIONID` cookie in browser dev tools.
- Set database, SMTP, and Razorpay secrets in the hosting environment. Use live
  payment keys only after completing payment, refund, and reconciliation reviews.
- Run the schema on a disposable local database first, provision the owner, and
  verify database backups and restore procedures.
- Razorpay payment webhooks now confirm captured orders. Refunds remain a manual
  provider operation. Before deploying this version to an existing database,
  apply `database/migrations/20260926_track_manual_refunds.sql` once. For an
  eligible future booking, staff must process and verify the refund in Razorpay,
  then use **Refund & Cancel** in the admin bookings page and record the returned
  `rfnd_...` reference. The application records the completed refund and cancels
  the booking; it does not call Razorpay's refund API. Reconcile this workflow in
  provider test mode before accepting bookings under a cancellation policy that
  promises refunds.
- Expired unpaid `Pending` bookings are released after 30 minutes by the web
  application. Keep at least one application instance running for cleanup.
- Admin reports use stored capture and refund event timestamps, booking records,
  and a selected date range, with CSV export. The `captured_at` and reporting
  indexes are included in `database/hotel.sql`; on an existing database, apply
  `database/migrations/20261009_report_payment_timestamps.sql` once after the
  refund migration. It approximates capture dates for currently captured legacy
  payments from `updated_at`; refunded legacy payments do not have a reliable
  capture timestamp and are not backfilled. Reconcile report totals against the
  payment provider before accounting or statutory use.
