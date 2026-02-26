#!/usr/bin/env python3
"""
Sync Individual Sponsor registrations from Luma to the codebase.

Fetches guests with "Individual Sponsor" tickets from the Luma API,
downloads their avatar images, and updates sponsor JSON + xcassets.
"""

import json
import os
import re
import sys
import tempfile
import unicodedata
from pathlib import Path

import requests
from PIL import Image

# Configuration
LUMA_API_BASE = "https://public-api.luma.com/v1"
LUMA_EVENT_ID = os.environ.get("LUMA_EVENT_ID", "evt-WHT17EaVs2of1Gs")
LUMA_API_KEY = os.environ["LUMA_API_KEY"]
TICKET_TYPE_NAME = "Individual Sponsor"
IMAGE_SIZE = (512, 512)

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
SPONSORS_JSON_PATHS = [
    REPO_ROOT / "DataClient/Sources/DataClient/Resources/2026-sponsors.json",
    REPO_ROOT / "iOS/Sources/DataClient/Resources/2026-sponsors.json",
]
XCASSETS_DIR = (
    REPO_ROOT / "iOS/Sources/SponsorFeature/Media.xcassets/Individual/2026"
)
SYNCED_GUESTS_PATH = REPO_ROOT / ".github/luma-synced-guests.json"


def fetch_individual_sponsors():
    """Fetch all guests with 'Individual Sponsor' ticket type from Luma."""
    headers = {"x-luma-api-key": LUMA_API_KEY}
    sponsors = []
    cursor = None

    while True:
        params = {
            "event_id": LUMA_EVENT_ID,
            "approval_status": "approved",
            "pagination_limit": 100,
        }
        if cursor:
            params["pagination_cursor"] = cursor

        resp = requests.get(
            f"{LUMA_API_BASE}/event/get-guests",
            headers=headers,
            params=params,
        )
        resp.raise_for_status()
        data = resp.json()

        for entry in data.get("entries", []):
            guest = entry.get("guest", {})
            tickets = guest.get("event_tickets", [])

            is_individual = any(
                t.get("name", "") == TICKET_TYPE_NAME for t in tickets
            )
            if not is_individual:
                continue

            answers = guest.get("registration_answers", [])
            icon_url = None
            social_link = None

            for answer in answers:
                q_type = answer.get("question_type", "")
                label = (answer.get("label") or "").lower()
                value = answer.get("value")

                if isinstance(value, str):
                    value = value.strip()

                if not value:
                    continue

                # Icon URL: look for url-type questions about icon/avatar/image
                if q_type == "url" and any(
                    kw in label
                    for kw in ["icon", "avatar", "image", "photo", "picture", "アイコン", "画像"]
                ):
                    icon_url = value
                # Social link: twitter, github, linkedin, or url with social keywords
                elif q_type in ("twitter", "github", "linkedin", "instagram"):
                    if not social_link:
                        social_link = value
                elif q_type == "url" and any(
                    kw in label
                    for kw in ["social", "sns", "link", "url", "website", "リンク", "ウェブ"]
                ):
                    if not social_link:
                        social_link = value

            sponsors.append(
                {
                    "guest_id": guest.get("id") or entry.get("api_id"),
                    "name": (guest.get("user_name") or "").strip(),
                    "icon_url": icon_url,
                    "social_link": social_link,
                }
            )

        if not data.get("has_more"):
            break
        cursor = data.get("next_cursor")
        if not cursor:
            break

    return sponsors


def load_synced_guests():
    if SYNCED_GUESTS_PATH.exists():
        return json.loads(SYNCED_GUESTS_PATH.read_text())
    return {}


def save_synced_guests(synced):
    SYNCED_GUESTS_PATH.parent.mkdir(parents=True, exist_ok=True)
    SYNCED_GUESTS_PATH.write_text(
        json.dumps(synced, indent=2, ensure_ascii=False) + "\n"
    )


def sanitize_image_key(name):
    """Convert a display name to an xcassets-safe image key.

    Examples:
      "Oka Yuji" -> "2026_OkaYuji"
      "문스콧 - Moon Scott" -> "2026_MoonScott"
    """
    # Remove parenthetical nicknames
    cleaned = re.sub(r"\s*\(.*?\)\s*", " ", name).strip()
    words = cleaned.split()
    # Remove separators
    words = [w for w in words if w != "-"]
    # Prefer Latin-alphabet words if available
    latin_words = [w for w in words if re.match(r"[A-Za-z]", w)]
    if latin_words:
        words = latin_words
    # Capitalize and remove non-alphanumeric
    parts = []
    for w in words:
        cleaned_w = re.sub(r"[^A-Za-z0-9\u00C0-\u024F]", "", w)
        if cleaned_w:
            parts.append(cleaned_w[0].upper() + cleaned_w[1:])
    result = "".join(parts)
    if not result:
        ascii_name = unicodedata.normalize("NFKD", name)
        ascii_name = ascii_name.encode("ascii", "ignore").decode("ascii")
        result = re.sub(r"[^A-Za-z0-9]", "", ascii_name)
    return f"2026_{result}" if result else None


def download_and_convert_image(url, dest_path):
    """Download image from URL and save as 512x512 PNG."""
    resp = requests.get(url, timeout=30)
    resp.raise_for_status()

    with tempfile.NamedTemporaryFile(suffix=".tmp", delete=False) as tmp:
        tmp.write(resp.content)
        tmp_path = tmp.name

    try:
        img = Image.open(tmp_path)
        img = img.convert("RGBA")
        img.thumbnail(IMAGE_SIZE, Image.LANCZOS)
        canvas = Image.new("RGBA", IMAGE_SIZE, (255, 255, 255, 0))
        offset = (
            (IMAGE_SIZE[0] - img.width) // 2,
            (IMAGE_SIZE[1] - img.height) // 2,
        )
        canvas.paste(img, offset)
        canvas.save(str(dest_path), "PNG")
    finally:
        os.unlink(tmp_path)


def create_imageset(image_key, icon_url):
    """Create xcassets imageset directory with image and Contents.json."""
    imageset_dir = XCASSETS_DIR / f"{image_key}.imageset"
    imageset_dir.mkdir(parents=True, exist_ok=True)

    dest_image = imageset_dir / f"{image_key}.png"
    download_and_convert_image(icon_url, dest_image)

    contents = {
        "images": [{"filename": f"{image_key}.png", "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {"template-rendering-intent": "original"},
    }
    (imageset_dir / "Contents.json").write_text(
        json.dumps(contents, indent=2) + "\n"
    )


def update_sponsors_json(new_sponsors):
    """Append new sponsors to the individual array in both JSON files."""
    for json_path in SPONSORS_JSON_PATHS:
        data = json.loads(json_path.read_text())
        individual = data.get("individual", [])

        max_id = max((s["id"] for s in individual), default=0)

        for sponsor in new_sponsors:
            max_id += 1
            entry = {
                "id": max_id,
                "name": sponsor["name"],
                "imageName": f"Individual/2026/{sponsor['image_key']}",
            }
            if sponsor.get("social_link"):
                entry["link"] = sponsor["social_link"]
            individual.append(entry)

        data["individual"] = individual
        json_path.write_text(
            json.dumps(data, indent=4, ensure_ascii=False) + "\n"
        )


def set_github_output(name, value):
    output_file = os.environ.get("GITHUB_OUTPUT")
    if output_file:
        with open(output_file, "a") as f:
            if "\n" in str(value):
                import uuid

                delimiter = uuid.uuid4().hex
                f.write(f"{name}<<{delimiter}\n{value}\n{delimiter}\n")
            else:
                f.write(f"{name}={value}\n")


def main():
    print("Fetching Individual Sponsor guests from Luma...")
    luma_sponsors = fetch_individual_sponsors()
    print(f"Found {len(luma_sponsors)} Individual Sponsor registrations")

    synced = load_synced_guests()

    sponsors_data = json.loads(SPONSORS_JSON_PATHS[0].read_text())
    existing_names = {
        s["name"].lower() for s in sponsors_data.get("individual", [])
    }

    new_sponsors = []
    for s in luma_sponsors:
        guest_id = s["guest_id"]
        name_lower = s["name"].lower()

        if guest_id in synced:
            print(f"  Skipping (already synced): {s['name']}")
            continue
        if name_lower in existing_names:
            print(f"  Skipping (name exists): {s['name']}")
            synced[guest_id] = {"name": s["name"], "status": "existing"}
            continue
        if not s["name"]:
            print(f"  Skipping (no name): guest_id={guest_id}")
            continue
        if not s["icon_url"]:
            print(f"  Skipping (no icon URL): {s['name']}")
            continue

        image_key = sanitize_image_key(s["name"])
        if not image_key:
            print(f"  Skipping (cannot generate image key): {s['name']}")
            continue

        # Handle image key collision
        if (XCASSETS_DIR / f"{image_key}.imageset").exists():
            image_key = f"{image_key}_{guest_id[-4:]}"

        s["image_key"] = image_key
        new_sponsors.append(s)

    if not new_sponsors:
        print("No new sponsors to add.")
        set_github_output("has_changes", "false")
        save_synced_guests(synced)
        return

    print(f"\nAdding {len(new_sponsors)} new sponsors:")
    summary_lines = []

    for s in new_sponsors:
        print(f"  - {s['name']} (image_key: {s['image_key']})")
        line = f"- **{s['name']}**"
        if s.get("social_link"):
            line += f" ({s['social_link']})"

        try:
            create_imageset(s["image_key"], s["icon_url"])
            print(f"    Image downloaded successfully")
        except Exception as e:
            print(f"    ERROR downloading image: {e}", file=sys.stderr)
            line += " (IMAGE DOWNLOAD FAILED)"

        summary_lines.append(line)
        synced[s["guest_id"]] = {
            "name": s["name"],
            "image_key": s["image_key"],
            "status": "added",
        }

    update_sponsors_json(new_sponsors)
    print("\nUpdated sponsor JSON files")

    save_synced_guests(synced)

    set_github_output("has_changes", "true")
    set_github_output("new_sponsors", "\n".join(summary_lines))

    print("\nSync complete!")


if __name__ == "__main__":
    main()
