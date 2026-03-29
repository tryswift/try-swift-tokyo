#!/usr/bin/env python3
"""
Fetch YouTube video metadata for try! Swift Tokyo talks.

This script fetches:
- Video IDs from YouTube playlists
- Transcripts with timestamps (via youtube-transcript-api)
- Chapter information from video descriptions

Usage:
    pip install google-api-python-client youtube-transcript-api
    python fetch_youtube_data.py --playlist-id PLCl5NM4qD3u_Azg7gKw5CK_DqSLeb4QMY --year 2024
    python fetch_youtube_data.py --playlist-id <PLAYLIST_ID> --year 2019

Environment:
    YOUTUBE_API_KEY: YouTube Data API v3 key (required for playlist/video metadata)

Requires: Python 3.10+ (uses list[dict] and X | None syntax)
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

try:
    from googleapiclient.discovery import build
except ImportError:
    print("Error: google-api-python-client not installed.")
    print("Run: pip install google-api-python-client")
    sys.exit(1)

try:
    from youtube_transcript_api import YouTubeTranscriptApi
except ImportError:
    print("Error: youtube-transcript-api not installed.")
    print("Run: pip install youtube-transcript-api")
    sys.exit(1)


def get_playlist_videos(youtube, playlist_id: str) -> list[dict]:
    """Fetch all videos from a YouTube playlist."""
    videos = []
    next_page_token = None

    while True:
        request = youtube.playlistItems().list(
            part="snippet,contentDetails",
            playlistId=playlist_id,
            maxResults=50,
            pageToken=next_page_token,
        )
        response = request.execute()

        for item in response.get("items", []):
            snippet = item["snippet"]
            videos.append(
                {
                    "video_id": item["contentDetails"]["videoId"],
                    "title": snippet["title"],
                    "description": snippet.get("description", ""),
                }
            )

        next_page_token = response.get("nextPageToken")
        if not next_page_token:
            break

    return videos


def parse_chapters(description: str) -> list[dict] | None:
    """Parse chapter timestamps from video description."""
    pattern = r"(\d{1,2}:\d{2}(?::\d{2})?)\s+(.+)"
    matches = re.findall(pattern, description)

    if len(matches) < 2:
        return None

    chapters = []
    for timestamp, title in matches:
        parts = timestamp.split(":")
        if len(parts) == 3:
            seconds = int(parts[0]) * 3600 + int(parts[1]) * 60 + int(parts[2])
        else:
            seconds = int(parts[0]) * 60 + int(parts[1])

        chapters.append({"title": title.strip(), "start_time": float(seconds)})

    return chapters if chapters else None


def fetch_transcript(video_id: str) -> list[dict] | None:
    """Fetch transcript for a YouTube video."""
    try:
        ytt_api = YouTubeTranscriptApi()
        transcript_list = ytt_api.fetch(video_id)
        entries = []
        for i, entry in enumerate(transcript_list):
            entries.append(
                {
                    "id": i + 1,
                    "start_time": round(entry.start, 2),
                    "end_time": round(entry.start + entry.duration, 2),
                    "text": entry.text,
                }
            )
        return entries if entries else None
    except Exception as e:
        print(f"  Warning: Could not fetch transcript for {video_id}: {e}")
        return None


def get_video_duration(youtube, video_id: str) -> float | None:
    """Fetch video duration in seconds."""
    try:
        request = youtube.videos().list(part="contentDetails", id=video_id)
        response = request.execute()
        if response["items"]:
            duration_str = response["items"][0]["contentDetails"]["duration"]
            return parse_iso_duration(duration_str)
    except Exception:
        pass
    return None


def parse_iso_duration(duration: str) -> float:
    """Parse ISO 8601 duration (PT1H2M3S) to seconds."""
    pattern = r"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?"
    match = re.match(pattern, duration)
    if not match:
        return 0.0
    hours = int(match.group(1) or 0)
    minutes = int(match.group(2) or 0)
    seconds = int(match.group(3) or 0)
    return float(hours * 3600 + minutes * 60 + seconds)


def load_session_titles(year: int, data_dir: Path) -> list[str]:
    """Load session titles from existing conference JSON files."""
    titles = []
    for day in ["day1", "day2", "day3"]:
        path = data_dir / f"{year}-{day}.json"
        if path.exists():
            with open(path) as f:
                data = json.load(f)
            for schedule in data.get("schedules", []):
                for session in schedule.get("sessions", []):
                    if session.get("description"):
                        titles.append(session["title"])
    return titles


def match_video_to_session(
    video_title: str, session_titles: list[str]
) -> str | None:
    """Try to match a YouTube video title to a session title."""
    video_lower = video_title.lower().strip()

    # Exact match
    for title in session_titles:
        if title.lower().strip() == video_lower:
            return title

    # Partial match (video title contains session title or vice versa)
    for title in session_titles:
        title_lower = title.lower().strip()
        if title_lower in video_lower or video_lower in title_lower:
            return title

    return None


def main():
    parser = argparse.ArgumentParser(
        description="Fetch YouTube video metadata for try! Swift Tokyo"
    )
    parser.add_argument(
        "--playlist-id", required=True, help="YouTube playlist ID"
    )
    parser.add_argument(
        "--year", type=int, required=True, help="Conference year (e.g. 2019)"
    )
    parser.add_argument(
        "--output-dir",
        default=None,
        help="Output directory (default: DataClient/Sources/DataClient/Resources/)",
    )
    parser.add_argument(
        "--api-key",
        default=None,
        help="YouTube API key (or set YOUTUBE_API_KEY env var)",
    )
    args = parser.parse_args()

    api_key = args.api_key or os.environ.get("YOUTUBE_API_KEY")
    if not api_key:
        print("Error: YouTube API key required.")
        print("Set YOUTUBE_API_KEY env var or use --api-key flag.")
        sys.exit(1)

    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    data_dir = repo_root / "DataClient" / "Sources" / "DataClient" / "Resources"
    output_dir = Path(args.output_dir) if args.output_dir else data_dir

    youtube = build("youtube", "v3", developerKey=api_key)

    print(f"Fetching videos from playlist {args.playlist_id}...")
    videos = get_playlist_videos(youtube, args.playlist_id)
    print(f"Found {len(videos)} videos")

    session_titles = load_session_titles(args.year, data_dir)
    print(f"Found {len(session_titles)} session titles for {args.year}")

    results = []
    for video in videos:
        video_id = video["video_id"]
        title = video["title"]
        description = video["description"]

        session_title = match_video_to_session(title, session_titles)
        if not session_title:
            print(f"  Skipping (no match): {title}")
            continue

        print(f"  Processing: {session_title} ({video_id})")

        duration = get_video_duration(youtube, video_id)
        chapters = parse_chapters(description)
        transcript = fetch_transcript(video_id)

        entry = {
            "session_title": session_title,
            "youtube_video_id": video_id,
        }
        if duration:
            entry["duration"] = duration
        if chapters:
            entry["chapters"] = chapters
        if transcript:
            entry["transcript"] = transcript

        results.append(entry)

    output_path = output_dir / f"{args.year}-videos.json"
    with open(output_path, "w") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print(f"\nWrote {len(results)} video entries to {output_path}")
    unmatched = len(videos) - len(results)
    if unmatched > 0:
        print(f"Warning: {unmatched} videos could not be matched to sessions")


if __name__ == "__main__":
    main()
