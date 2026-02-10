# Salon Flutter App – User Modules

## Auth & Identity
- Onboarding slider, login/signup, forgot/change password.
- Firebase auth wrapper decides user vs owner/admin path; drawer shows logout.

## Home & Discovery
- Home feed with offers and experts search, location picker (Google Map).
- Services catalog and details (hair, makeup, massage, facial, mehndi, waxing, photoshoot).
- Gallery, FAQs, contact, share-with-friends.

## Booking
- Service appointment booking form (name/date/time/phone).
- User appointment list with cancel.

## Courses
- Course catalog (basic/advanced/pro), detail pages, apply form; applied list screen.

## Notifications
- Client-side notification list backed by in-memory store.

## Profile & Settings
- Personal info screen, change password entry, drawer navigation (profile, notifications, about).

## Admin 20% (Mobile, on-the-go)
- Quick approvals: see all appointments and approve/cancel (no deep edits).
- Expiring reservations: view near-term reservations and mark paid/confirm.
- Course applications: approve/cancel applied candidates.
- Alerts: notifications list for booking/application changes.
- Role switch: toggle to owner/admin mode from drawer when permitted.
