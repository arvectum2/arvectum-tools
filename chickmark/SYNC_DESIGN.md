# ChickMark — Sync design

Updated: 2026-10-01

## Invariant

The product remains local-first. A user can view and change today's habits on Apple Watch while the iPhone is temporarily unreachable. Synchronization must converge later without asking the user to resolve technical conflicts.

## iPhone ↔ Apple Watch transport

WatchConnectivity uses two paths:

- sendMessage for low-latency updates while the counterpart is reachable;
- transferUserInfo for durable delivery while the counterpart is offline.

The iPhone also publishes the latest Today snapshot using updateApplicationContext. The Watch persists the latest received snapshot in UserDefaults so it can launch usefully when the phone is unavailable.

## Commands are desired state, not toggles

A Watch action sends a stable command UUID, habit UUID, stable local calendar dayKey (YYYY-MM-DD), and desired completion state. The iPhone applies set-completed / set-not-completed idempotently. Replaying the same command or receiving duplicate durable transfers cannot invert state.

The iPhone keeps recent acknowledged command IDs and includes them in snapshots. The Watch removes acknowledged commands from its local pending queue.

## Optimistic Watch behavior

A tap updates Watch UI immediately and stores the command before attempting transport. When an authoritative iPhone snapshot arrives, the Watch overlays still-unacknowledged local commands on that snapshot. This prevents a stale snapshot from visually undoing an offline user action.

After acknowledgement, the iPhone state becomes authoritative for the completed command and the pending command is removed.

## Conflict rule

For the current binary completion model, the most recently delivered unacknowledged local Watch desired state is shown optimistically. Once commands reach the iPhone, the iPhone applies them in delivery order and publishes the resulting authoritative snapshot.

Before CloudKit multi-device sync ships, the conflict model will be extended with per-day mutation timestamps so simultaneous edits from multiple iPhones/iPads can use deterministic last-write-wins semantics without relying on transport order.

## Calendar / timezone semantics

Historical actions are attached to the local calendar day on which they were made via the stored dayKey.

- Watch commands carry that day key explicitly.
- The iPhone reconstructs a neutral noon date only as storage support; the day key remains the identity of the habit day.
- Current schedules and reminders follow the device's current local timezone.
- Travelling does not retroactively move historical check-ins to another day.

## Tested simulator scenarios

Paired watchOS 27 / iOS 27 simulators:

1. iPhone snapshot appears on an already running Watch.
2. Watch one-tap completion updates SwiftData on iPhone and returns to Watch.
3. iPhone-side completion updates an already running Watch.
4. With iPhone Simulator shut down, Watch changes state immediately and retains it.
5. After iPhone boots again, the durable command is applied and both devices converge.

The Watch app is embedded under the iPhone app's Watch/ directory and Xcode's embedded binary validator passes.
