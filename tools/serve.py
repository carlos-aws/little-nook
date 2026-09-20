#!/usr/bin/env python3
"""Serve a Web export locally. Zero dependencies; no remote binding by default."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import argparse
import functools

parser = argparse.ArgumentParser()
parser.add_argument("--port", type=int, default=8081)
parser.add_argument("--bind", default="127.0.0.1")
args = parser.parse_args()
folder = Path(__file__).resolve().parents[1] / "build/web"
if not (folder / "index.html").exists():
    raise SystemExit("Export first: tools/export.sh Web")

class Handler(SimpleHTTPRequestHandler):
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm"}

print(f"Little Nook: http://{args.bind}:{args.port}", flush=True)
ThreadingHTTPServer((args.bind, args.port), functools.partial(Handler, directory=folder)).serve_forever()
