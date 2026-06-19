# Play Data Safety form

Every app must complete **Policy → App content → Data safety** in Play Console.
Answers must match what the app actually does and the privacy policy. This is a
manual, one-time form (re-visit when data handling changes).

## Decide per data type

For each type the app touches (e.g. *Personal info → Email/User IDs*, *Photos*,
*App activity*, *Device IDs*), answer:

1. **Collected?** Sent off the device.
2. **Shared?** Sent to a third party.
3. **Purpose** — app functionality, analytics, ads, personalization, etc.
4. **Required or optional** for the user.
5. **Processed ephemerally** vs. stored.

Also declare globally:

- **Encryption in transit** — yes if all network traffic is HTTPS/TLS.
- **Deletion** — whether users can request data deletion, and how.

## Fill this in for your app

| Data type | Collected | Shared | Purpose | Notes |
|-----------|-----------|--------|---------|-------|
| {{e.g. User ID}} | {{yes/no}} | {{yes/no}} | {{App functionality}} | {{from Google/Apple sign-in}} |
| {{Photos}} | {{...}} | {{...}} | {{...}} | {{on-device only?}} |
| {{Device/other IDs}} | {{...}} | {{...}} | {{...}} | {{}} |

## Rules of thumb

- Data that never leaves the device is **not** "collected".
- Sending data to your own backend over HTTPS = collected, encrypted in transit,
  not necessarily shared (sharing means a separate company).
- Third-party SDKs (analytics, ads, crash reporting) count — include their data.
- Keep this form, the store listing's privacy section, and the privacy policy
  consistent. Mismatches cause rejections.
