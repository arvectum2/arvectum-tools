#!/usr/bin/env python3
"""Disposable-data, genuine WCSession paired simulator acceptance.

Never boots/pairs/deletes devices, never touches physical iPhone/Watch.
Requires installed DEBUG ChickMark with --debug-suspend-watch-delivery support.
The caller explicitly consents to changing the QA habits in the two sims.
"""
import argparse
import json
import pathlib
import plistlib
import re
import sqlite3
import subprocess
import time

PHONE_BUNDLE = "ru.arvectum.tools.habits"
WATCH_BUNDLE = PHONE_BUNDLE + ".watch"
QA_READING_ID = "00000000-0000-0000-0000-000000000001"


def run(*args, timeout=30, ignore=False):
    p = subprocess.run(args, text=True, capture_output=True, timeout=timeout)
    if p.returncode and not ignore:
        raise RuntimeError(f"{args}: {(p.stdout + p.stderr)[-700:]}")
    return p.stdout.strip()


def app_root(device, bundle, kind="data"):
    return pathlib.Path(run("xcrun", "simctl", "get_app_container", device, bundle, kind))


def prefs(device, bundle):
    with (app_root(device, bundle) / "Library/Preferences" / (bundle + ".plist")).open("rb") as f:
        return plistlib.load(f)


def watch_state(watch):
    data = prefs(watch, WATCH_BUNDLE)
    return (
        json.loads(data["habits.watch.cachedSnapshot"]),
        json.loads(data["habits.watch.pendingCommands"]),
    )


def phone_state(phone):
    root = app_root(phone, PHONE_BUNDLE)
    db = root / "Library/Application Support/Habits.store"
    # Read only this fixed disposable QA habit, not unrelated simulator data.
    habit_hex = QA_READING_ID.replace("-", "")
    with sqlite3.connect(f"file:{db}?mode=ro", uri=True) as conn:
        rows = conn.execute(
            "select count(*) from ZHABITCHECKIN where hex(ZHABITID)=?",
            (habit_hex,)
        ).fetchone()[0]
        revisions = conn.execute(
            "select count(*) from ZHABITDAYMUTATION where hex(ZHABITID)=?",
            (habit_hex,)
        ).fetchone()[0]
    return rows, revisions, prefs(phone, PHONE_BUNDLE).get("habits.watch.recentCommandIDs", [])


def restart_watch(watch, *flags):
    run("xcrun", "simctl", "terminate", watch, WATCH_BUNDLE, ignore=True)
    run("xcrun", "simctl", "launch", watch, WATCH_BUNDLE, "--diagnose-watch-sync", *flags)


def wait_for(description, predicate, timeout=45):
    until = time.monotonic() + timeout
    last = None
    while time.monotonic() < until:
        try:
            ok, detail = predicate()
            last = detail
            if ok:
                print("PASS", description, detail, flush=True)
                return detail
        except (ValueError, KeyError, OSError, sqlite3.OperationalError) as e:
            last = str(e)
        time.sleep(1)
    raise RuntimeError(f"TIMEOUT {description}; last={last!r}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phone", required=True)
    parser.add_argument("--watch", required=True)
    parser.add_argument("--allow-disposable-sim-state", action="store_true")
    args = parser.parse_args()
    if not args.allow_disposable_sim_state:
        parser.error("Must explicitly pass --allow-disposable-sim-state")
    for id in (args.phone, args.watch):
        if not re.fullmatch(r"[a-fA-F0-9-]{36}", id):
            parser.error("Use exact CoreSimulator UUIDs only")
    booted = run("xcrun", "simctl", "list", "devices", "booted")
    if args.phone not in booted or args.watch not in booted:
        parser.error("Both devices must already be booted iOS/watchOS simulators")
    pairs = run("xcrun", "simctl", "list", "pairs")
    if not re.search(
        rf"\(active, connected\).*?Watch:.*?{re.escape(args.watch)}.*?Phone:.*?{re.escape(args.phone)}",
        pairs, re.S,
    ):
        parser.error("The two selected simulators are not an active connected pair")
    for uuid, bundle in ((args.phone, PHONE_BUNDLE), (args.watch, WATCH_BUNDLE)):
        _ = app_root(uuid, bundle)
        version = run("plutil", "-extract", "CFBundleVersion", "raw",
                      str(app_root(uuid, bundle, "app") / "Info.plist"))
        print("TARGET", bundle, "version", version, uuid, flush=True)

    # Start only the installed QA app, with iCloud deliberately disabled.
    run("xcrun", "simctl", "terminate", args.phone, PHONE_BUNDLE, ignore=True)
    run("xcrun", "simctl", "launch", args.phone, PHONE_BUNDLE,
        "--disable-cloud-sync", "--seed-watch-sync-demo", "--diagnose-watch-sync")
    restart_watch(args.watch)
    def initial():
        snap, queue = watch_state(args.watch)
        rows, ledger, _ = phone_state(args.phone)
        names = [h.get("id", "").upper() for h in snap["habits"]]
        good = (bool(names) and names[0] == QA_READING_ID and not queue and
                not snap["habits"][0]["completed"] and rows == 0)
        return good, f"checkins={rows} ledger={ledger} watch={snap['completedCount']} pending={len(queue)}"
    wait_for("precondition: known QA habit unchecked, no pending work", initial)
    baseline_rows, baseline_ledger, _ = phone_state(args.phone)
    expected_ledger = max(baseline_ledger, 1)

    # Queue true offline (application transport suppression, not radio outage).
    restart_watch(args.watch, "--debug-suspend-watch-delivery", "--auto-toggle-first-habit")
    def queued(expected):
        snap, queue = watch_state(args.watch)
        rows, _, _ = phone_state(args.phone)
        good = (len(queue) == 1 and queue[0]["completed"] is expected and
                snap["habits"][0]["completed"] is expected and rows == baseline_rows)
        return good, (queue[0]["id"] if queue else "no-id", len(queue), rows)
    first = wait_for("offline simulated: check queued but phone unchanged",
                     lambda: queued(True))[0]

    restart_watch(args.watch, "--debug-suspend-watch-delivery", "--auto-toggle-cached-first-habit")
    second = wait_for("offline simulated: restart+undo supersedes check",
                      lambda: queued(False))[0]
    assert first != second, "Undo must have a new UUID"

    restart_watch(args.watch)
    def acked(completed, count, expected_id):
        snap, queue = watch_state(args.watch)
        rows, ledger, IDs = phone_state(args.phone)
        ok = (not queue and snap["completedCount"] == int(completed) and
              rows == count and ledger == expected_ledger and
              expected_id in IDs and expected_id in snap.get("acknowledgedCommandIDs", []))
        return ok, f"pending={len(queue)} watch={snap['completedCount']} checkins={rows} ledger={ledger} ACK={expected_id in IDs}"
    wait_for("real WatchConnectivity: latest undo delivered and ACKed",
             lambda: acked(False, baseline_rows, second), timeout=65)

    restart_watch(args.watch, "--debug-suspend-watch-delivery", "--auto-toggle-first-habit")
    third = wait_for("offline simulated: new check queued",
                     lambda: queued(True))[0]
    restart_watch(args.watch)
    wait_for("real WatchConnectivity: check delivered exactly once",
             lambda: acked(True, baseline_rows + 1, third), timeout=65)

    before_undo_ids = set(phone_state(args.phone)[2])
    restart_watch(args.watch, "--auto-toggle-cached-first-habit")
    def online_undo():
        snap, queue = watch_state(args.watch)
        rows, ledger, phone_ids = phone_state(args.phone)
        new_ids = set(phone_ids) - before_undo_ids
        ok = (
            not queue and snap["completedCount"] == 0 and
            rows == baseline_rows and ledger == expected_ledger and
            bool(new_ids) and
            new_ids.issubset(set(snap.get("acknowledgedCommandIDs", [])))
        )
        return ok, f"pending={len(queue)} watch={snap['completedCount']} checkins={rows} new_phone_ACKs={len(new_ids)}"
    wait_for("real WatchConnectivity: online undo converges",
             online_undo, timeout=65)

    print("SIMULATOR_A2_ACCEPTANCE_PASS: real WCSession command+ACK, "
          "offline simulated queue/compaction, Watch restart, no duplicate checkins", flush=True)


if __name__ == "__main__":
    main()
