#!/usr/bin/env python3
"""
Curate and validate the 152-exercise static catalog for GymGym-A.

Source : https://github.com/hasaneyldrm/exercises-dataset (data/exercises.json, 1324 items)
Output : assets/data/exercises.json (152 verified exercises)
         assets/gifs/*.gif, assets/thumbs/*.jpg (180x180 media files)

Usage:
  python scripts/clean_dataset.py                       # fetch source from pinned commit
  python scripts/clean_dataset.py --source ./ex.json    # read from local source file
  python scripts/clean_dataset.py --no-media            # generate JSON only without downloading media
"""
import argparse
import json
import re
import struct
import sys
import urllib.request
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

REPO = "hasaneyldrm/exercises-dataset"
PINNED_COMMIT = "7455efae41b330c265e7cd4b78dfa848e7ce5ebd"
RAW = f"https://raw.githubusercontent.com/{REPO}/{PINNED_COMMIT}"
ATTRIBUTION = "\u00a9 Gym visual \u2014 https://gymvisual.com/"
SCHEMA_VERSION = 1
TOTAL = 152

# Map source categories to the 6 primary muscle groups in the app
CATEGORY_TO_GROUP = {
    "chest": "chest",
    "back": "back",
    "upper legs": "legs",
    "lower legs": "legs",
    "shoulders": "shoulders",
    "upper arms": "arms",
    "lower arms": "arms",
    "waist": "core",
}

# Normalize equipment values to the 5 supported categories
EQUIPMENT_MAP = {
    "barbell": "barbell", "ez barbell": "barbell", "olympic barbell": "barbell", "trap bar": "barbell",
    "dumbbell": "dumbbell",
    "cable": "cable",
    "leverage machine": "machine", "smith machine": "machine", "sled machine": "machine",
    "body weight": "bodyweight",
}

# Target counts per primary muscle group (total = 152)
QUOTA = {"chest": 26, "back": 28, "legs": 30, "shoulders": 24, "arms": 28, "core": 16}

# Curated exercise manifest: (source_id, "C"=compound | "I"=isolation)
C, I = "C", "I"
SELECTION = {
    "chest": [
        ("0025", C), ("0047", C), ("0033", C),
        ("0289", C), ("0314", C), ("0301", C), ("0308", I), ("0319", I), ("0375", I),
        ("0155", I), ("0179", I), ("0171", I), ("0158", I), ("2144", C), ("0227", I),
        ("0576", C), ("1299", C), ("1300", C), ("0596", I), ("0748", C), ("0757", C),
        ("0662", C), ("0279", C), ("0493", C), ("0251", C), ("1311", C),
    ],
    "back": [
        ("0652", C), ("1326", C), ("1429", C), ("0651", C), ("0017", C),
        ("0150", C), ("2616", C), ("0818", C), ("0238", I), ("0579", C), ("2285", I), ("1347", C),
        ("0027", C), ("3017", C), ("0293", C), ("0292", C), ("0327", C),
        ("0861", C), ("0218", C), ("0189", C), ("1350", C), ("0606", C), ("0581", C), ("0499", C),
        ("0095", I), ("0406", I), ("0604", I),
        ("0489", I),
    ],
    "legs": [
        ("0043", C), ("0042", C), ("0413", C), ("1760", C), ("0054", C), ("0336", C),
        ("1460", C), ("0743", C), ("0739", C), ("0585", I), ("0770", C), ("0410", C),
        ("0032", C), ("0085", C), ("1459", C), ("0811", C), ("1409", C), ("0044", C),
        ("0599", I), ("0586", I), ("0196", I), ("0431", C), ("3193", I),
        ("0605", I), ("0594", I), ("0417", I), ("1373", I), ("1372", I),
        ("0597", I), ("0598", I),
    ],
    "shoulders": [
        ("0091", C), ("1456", C), ("0426", C), ("0405", C), ("2137", C),
        ("0603", C), ("0587", C), ("0766", C), ("0219", C),
        ("0334", I), ("0178", I), ("0584", I), ("0192", I),
        ("0310", I), ("0041", I), ("0162", I),
        ("0380", I), ("0602", I), ("0203", I), ("0378", I), ("0075", I),
        ("0120", C), ("0437", C), ("0246", C),
    ],
    "arms": [
        ("0031", I), ("0447", I), ("0070", I), ("0294", I), ("0313", I), ("0318", I),
        ("0297", I), ("0868", I), ("0165", I), ("0592", I), ("0439", I),
        ("0030", C), ("0296", C), ("0751", C), ("0814", C), ("0129", C), ("0283", C), ("0591", C),
        ("0060", I), ("0201", I), ("0200", I), ("0194", I), ("0333", I), ("0607", I),
        ("0126", I), ("0082", I), ("0369", I), ("0385", I),
    ],
    "core": [
        ("0274", I), ("0872", I), ("0687", I), ("0472", C), ("0276", C), ("0705", C),
        ("0277", I), ("0003", I),
        ("0084", C),
        ("0175", I), ("0226", I), ("0222", I), ("0243", I),
        ("0407", I),
        ("1452", I), ("0583", I),
    ],
}

def split_tags(group, target):
    if group == "chest" or group == "shoulders":
        return ["push", "upper", "full_body"]
    if group == "back":
        return ["pull", "upper", "full_body"]
    if group == "legs":
        return ["legs", "lower", "full_body"]
    if group == "arms":
        if target == "triceps":
            return ["push", "upper", "full_body"]
        return ["pull", "upper", "full_body"]
    if group == "core":
        return ["push", "pull", "legs", "upper", "lower", "full_body"]
    raise ValueError(group)

MOJIBAKE = {"\u0432\u00b0": "\u00b0"}

def clean_name(raw):
    s = raw.strip()
    for bad, good in MOJIBAKE.items():
        s = s.replace(bad, good)
    s = re.sub(r"\s+", " ", s)
    words = []
    for w in s.split(" "):
        if w.lower() == "ez":
            words.append("EZ")
        elif w[:1].isalpha():
            words.append(w[:1].upper() + w[1:])
        elif w[:1] == "(" and len(w) > 1:
            words.append("(" + w[1:2].upper() + w[2:])
        else:
            words.append(w)
    return " ".join(words)

def fetch(url, timeout=30):
    req = urllib.request.Request(url, headers={"User-Agent": "gymgym-clean/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()

def load_source(src):
    raw = fetch(f"{RAW}/data/exercises.json") if src.startswith("http") or src == "remote" else Path(src).read_bytes()
    return json.loads(raw.decode("utf-8"))

def validate_manifest(src_by_id):
    ids = [i for g in SELECTION.values() for i, _ in g]
    errors = []
    if len(ids) != TOTAL:
        errors.append(f"manifest count {len(ids)} != expected {TOTAL}")
    dup = [i for i, c in Counter(ids).items() if c > 1]
    if dup:
        errors.append(f"duplicate id in manifest: {dup}")
    for g, quota in QUOTA.items():
        if len(SELECTION[g]) != quota:
            errors.append(f"{g}: {len(SELECTION[g])} != quota {quota}")
    seen_names = {}
    for g, items in SELECTION.items():
        for i, _ in items:
            e = src_by_id.get(i)
            if e is None:
                errors.append(f"{i}: missing in source"); continue
            if CATEGORY_TO_GROUP.get(e["category"]) != g:
                errors.append(f"{i} {e['name']}: category {e['category']} mismatch for {g}")
            if e["equipment"] not in EQUIPMENT_MAP:
                errors.append(f"{i} {e['name']}: unsupported equipment {e['equipment']}")
            for lang in ("en", "tr"):
                if not (e["instructions"].get(lang) or "").strip() or not e["instruction_steps"].get(lang):
                    errors.append(f"{i}: missing {lang} instructions")
            key = e["name"].strip().lower()
            if key in seen_names:
                errors.append(f"{i}: duplicate name ({key}) ~ {seen_names[key]}")
            seen_names[key] = i
            if e.get("attribution") != ATTRIBUTION:
                errors.append(f"{i}: unexpected attribution value")
    return errors

def check_gif(data):
    if data[:6] not in (b"GIF87a", b"GIF89a"):
        return "invalid GIF header"
    w, h = struct.unpack("<HH", data[6:10])
    if (w, h) != (180, 180):
        return f"dimensions {w}x{h} != 180x180"
    return None

def download_media(entries, out_dir):
    gifs, thumbs = Path(out_dir) / "gifs", Path(out_dir) / "thumbs"
    gifs.mkdir(parents=True, exist_ok=True); thumbs.mkdir(parents=True, exist_ok=True)

    def one(e):
        problems = []
        for kind, rel, dest, check in (
            ("gif", e["gif_url"], gifs, check_gif),
            ("thumb", e["image"], thumbs, lambda d: None if d[:2] == b"\xff\xd8" else "invalid JPEG header"),
        ):
            try:
                data = fetch(f"{RAW}/{rel}")
                err = check(data) if len(data) > 0 else "empty file"
                if err:
                    problems.append(f"{e['id']} {kind}: {err}")
                else:
                    (dest / Path(rel).name).write_bytes(data)
            except Exception as ex:  # noqa: BLE001
                problems.append(f"{e['id']} {kind}: {ex}")
        return problems

    with ThreadPoolExecutor(max_workers=8) as ex:
        return [p for ps in ex.map(one, entries) for p in ps]

def build_record(e, group, mtype):
    gif_name = Path(e["gif_url"]).name
    thumb_name = Path(e["image"]).name
    return {
        "id": e["id"],
        "name": clean_name(e["name"]),
        "nameTr": None,
        "primaryMuscle": group,
        "targetMuscle": e["target"],
        "secondaryMuscles": sorted(set(e.get("secondary_muscles") or [])),
        "equipment": EQUIPMENT_MAP[e["equipment"]],
        "equipmentSource": e["equipment"],
        "movementType": "compound" if mtype == C else "isolation",
        "splitTags": split_tags(group, e["target"]),
        "instructions": {"en": e["instructions"]["en"].strip(), "tr": e["instructions"]["tr"].strip()},
        "instructionSteps": {"en": [s.strip() for s in e["instruction_steps"]["en"]],
                             "tr": [s.strip() for s in e["instruction_steps"]["tr"]]},
        "gifPath": f"assets/gifs/{gif_name}",
        "thumbPath": f"assets/thumbs/{thumb_name}",
        "mediaId": e["media_id"],
        "attribution": ATTRIBUTION,
    }

def coverage_report(records):
    problems = []
    for g in QUOTA:
        cs = sum(1 for r in records if r["primaryMuscle"] == g and r["movementType"] == "compound")
        iso = sum(1 for r in records if r["primaryMuscle"] == g and r["movementType"] == "isolation")
        min_c, min_i = (3, 3) if g == "core" else (6, 3)
        if cs < min_c or iso < min_i:
            problems.append(f"{g}: compound={cs} (min {min_c}), isolation={iso} (min {min_i})")
    for day in ("push", "pull", "legs", "upper", "lower", "full_body"):
        dr = [r for r in records if day in r["splitTags"]]
        if len({r["primaryMuscle"] for r in dr if r["primaryMuscle"] != "core"}) == 0:
            problems.append(f"split tag {day}: empty")
    return problems

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", default="remote", help="local exercises.json path or 'remote'")
    ap.add_argument("--out", default="assets/data/exercises.json")
    ap.add_argument("--assets-dir", default="assets")
    ap.add_argument("--no-media", action="store_true")
    args = ap.parse_args()

    data = load_source(args.source)
    print(f"Source record count: {len(data)}")
    src_by_id = {e["id"]: e for e in data}
    assert len(src_by_id) == len(data), "duplicate IDs found in source"

    errors = validate_manifest(src_by_id)
    if errors:
        print("MANIFEST ERRORS:\n  " + "\n  ".join(errors)); sys.exit(1)

    entries, records = [], []
    for g, items in SELECTION.items():
        for i, mt in items:
            entries.append(src_by_id[i]); records.append(build_record(src_by_id[i], g, mt))

    cov = coverage_report(records)
    if cov:
        print("COVERAGE ERRORS:\n  " + "\n  ".join(cov)); sys.exit(1)

    if not args.no_media:
        media_problems = download_media(entries, args.assets_dir)
        if media_problems:
            print("MEDIA ERRORS:\n  " + "\n  ".join(media_problems)); sys.exit(1)
        print(f"Media verified: {len(entries)} GIFs (180x180) + {len(entries)} thumbnails")

    doc = {
        "schemaVersion": SCHEMA_VERSION,
        "generatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "count": len(records),
        "source": {"repo": f"https://github.com/{REPO}", "commit": PINNED_COMMIT,
                   "dataLicense": "MIT", "mediaLicense": "\u00a9 Gym visual (180x180 attribution required)"},
        "attribution": ATTRIBUTION,
        "exercises": records,
    }
    out = Path(args.out); out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"Wrote: {out} ({len(records)} exercises)")
    print("Muscle groups:", dict(Counter(r["primaryMuscle"] for r in records)))
    print("Equipment    :", dict(Counter(r["equipment"] for r in records)))
    print("Movement type:", dict(Counter(r["movementType"] for r in records)))

if __name__ == "__main__":
    main()
