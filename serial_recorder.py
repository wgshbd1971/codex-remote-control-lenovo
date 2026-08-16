#!/usr/bin/env python3
"""Receive-only serial recorder deployed through the Lenovo control kit."""

from __future__ import annotations

import argparse
import json
import os
import signal
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import serial
from serial.tools import list_ports

ROOT = Path(os.environ.get("CODEX_REMOTE_ROOT", r"C:\CodexRemote" if os.name == "nt" else "."))
LOG_DIR = ROOT / "logs"


def cmd_ports(_: argparse.Namespace) -> int:
    ports = list(list_ports.comports())
    if not ports:
        print("No serial ports found.")
        return 1
    for port in ports:
        print(f"{port.device}\t{port.description}\t{port.hwid}")
    return 0


def cmd_capture(args: argparse.Namespace) -> int:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    stem = LOG_DIR / f"capture-{stamp}-{args.port.replace(':', '_')}"
    raw_path = stem.with_suffix(".bin")
    text_path = stem.with_suffix(".log")
    meta_path = stem.with_suffix(".json")
    settings = {
        "port": args.port,
        "baud": args.baud,
        "bytesize": args.bytesize,
        "parity": args.parity,
        "stopbits": args.stopbits,
        "seconds": args.seconds,
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "receive_only": True,
    }
    meta_path.write_text(json.dumps(settings, indent=2), encoding="utf-8")
    stop = False

    def request_stop(_signum: int, _frame: object) -> None:
        nonlocal stop
        stop = True

    signal.signal(signal.SIGINT, request_stop)
    if hasattr(signal, "SIGTERM"):
        signal.signal(signal.SIGTERM, request_stop)

    deadline = time.monotonic() + args.seconds if args.seconds > 0 else None
    total = 0
    print(f"Capturing {args.port} at {args.baud}; raw={raw_path}; log={text_path}", flush=True)
    try:
        with serial.Serial(
            port=args.port,
            baudrate=args.baud,
            bytesize=args.bytesize,
            parity=args.parity,
            stopbits=args.stopbits,
            timeout=0.2,
            write_timeout=0.2,
        ) as device, raw_path.open("ab") as raw, text_path.open("a", encoding="utf-8") as text:
            while not stop and (deadline is None or time.monotonic() < deadline):
                chunk = device.read(max(1, device.in_waiting))
                if not chunk:
                    continue
                now = datetime.now(timezone.utc).isoformat(timespec="milliseconds")
                raw.write(chunk)
                raw.flush()
                text.write(f"{now}  {chunk.hex(' ')}\n")
                text.flush()
                total += len(chunk)
    except serial.SerialException as exc:
        print(f"Serial error: {exc}", file=sys.stderr)
        return 2
    print(f"Capture complete: {total} bytes", flush=True)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    ports = sub.add_parser("ports", help="list serial ports")
    ports.set_defaults(func=cmd_ports)
    capture = sub.add_parser("capture", help="capture serial data without transmitting")
    capture.add_argument("--port", required=True)
    capture.add_argument("--baud", required=True, type=int)
    capture.add_argument("--seconds", type=int, default=60, help="0 means until interrupted")
    capture.add_argument("--bytesize", type=int, choices=(5, 6, 7, 8), default=8)
    capture.add_argument("--parity", choices=("N", "E", "O", "M", "S"), default="N")
    capture.add_argument("--stopbits", type=float, choices=(1, 1.5, 2), default=1)
    capture.set_defaults(func=cmd_capture)
    return parser


if __name__ == "__main__":
    parsed = build_parser().parse_args()
    raise SystemExit(parsed.func(parsed))
