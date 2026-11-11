# ADR-0025 — Waiting in the background: an ETA notification, polling in the foreground
Status: Accepted
Date: 2026-09-29

## Context
A chorus video takes ≈ 10 min, a full one ≈ 30 min. iOS suspends the app soon
after it leaves the foreground; the Dart poller stops.

## Options
a) BGAppRefresh with a second Dart engine: not guaranteed to run, and the
   signing chain (App Attest, HMAC, clock sync) lives in Dart.
b) A local notification at the platform's ETA; polling resumes in the foreground.

## Decision
b. New side channel `songlet/notifications` (+ `/events`),
`NotificationService.swift` (UNUserNotificationCenter; no push, no APNs token,
no Info.plist change, no Required-Reason API): `requestAuthorization`,
`schedule({id, title, body, afterSeconds, location})`, `cancel({id})`, and an
event stream of opened notifications' locations (a tap that launched the app is
held until Dart listens). Dart port `LocalNotifications`
(`platform/domain/local_notifications.dart`; the plan named it
`NotificationScheduler` in `native_gateways.dart` — a naming change only).
`MvNotifications` schedules `mv.<videoId>` when the platform accepts a video
(permission asked then, in context), never sooner than a minute, and cancels it
when the run settles while the app runs. The app binds the localized copy and
the target (the video's progress page, which forwards to the video when it is
ready) in `MvNotificationBinding`. On foreground, `musicVideosProvider` is
invalidated so pending videos are polled again; on launch they are resumed.

## Consequences
The notification says the video *should* be ready (the ETA), not that it is.
