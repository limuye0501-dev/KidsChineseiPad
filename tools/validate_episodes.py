#!/usr/bin/env python3
"""Check the shipped episode JSON before CI spends time in Xcode."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EPISODES = ROOT / "LittlePandaChinese" / "Resources" / "Episodes"


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    sys.exit(1)


def spoken_lines(beat):
    for key in ("prompt", "answer", "correction"):
        line = beat.get(key)
        if line:
            yield key, line


def main() -> None:
    catalog = json.loads((EPISODES / "catalog.json").read_text(encoding="utf-8"))
    if catalog.get("freeThrough") != 2:
        fail("first two episodes should be free")
    shelf = catalog["shelf"]
    if [item.get("number") or 1 for item in shelf] != [1, 2, 3, 4, 5]:
        # The playable file carries its own number; the placeholder cards carry number.
        numbers = []
        for item in shelf:
            if "episode" in item:
                numbers.append(1)
            else:
                numbers.append(item.get("number"))
        if numbers != [1, 2, 3, 4, 5]:
            fail(f"unexpected shelf {numbers}")
    episode = json.loads((EPISODES / "episode-01-colors.json").read_text(encoding="utf-8"))
    if not episode.get("free") or episode.get("number") != 1:
        fail("episode 1 should be free")
    beats = episode["beats"]
    ids = [beat["id"] for beat in beats]
    if len(ids) != len(set(ids)):
        fail("duplicate beat ids")
    if any(re.search(r"[A-Za-z]", line["spoken"]) for beat in beats for _, line in spoken_lines(beat)):
        fail("spoken lines must be Chinese, not pinyin")
    questions = [beat["prompt"]["hanzi"] for beat in beats if beat["role"] == "question"]
    answers = [beat["prompt"]["hanzi"] for beat in beats if beat["role"] == "answer"]
    if questions != ["这是什么颜色？"] * 4:
        fail(f"questions {questions}")
    if answers != ["它是红色的！", "它是黄色的！", "它是蓝色的！", "它是绿色的！"]:
        fail(f"answers {answers}")
    vocab = [beat["card"]["hanzi"] for beat in beats if beat["kind"] == "vocab"]
    if vocab != ["红", "黄", "蓝", "绿"] * 2:
        fail(f"vocab {vocab}")
    quizzes = [beat for beat in beats if beat["kind"] == "quiz"]
    if len(quizzes) != 3 or any(beat.get("quizPause") != 3 for beat in quizzes):
        fail("quiz pause must be 3 seconds")
    if quizzes[1].get("twist") is not True or quizzes[1]["prompt"]["hanzi"] != "是蓝色的吗？":
        fail("missing blue twist")
    if quizzes[1]["correction"]["spoken"] != "不是。它是黄色的！":
        fail("twist correction")
    total = sum(beat["duration"] for beat in beats)
    if abs(total - 149) > 0.001:
        fail(f"nominal duration {total}, expected 149")
    if not any(beat.get("cans") == "fall" for beat in beats):
        fail("missing paint-can joke")
    if not any(beat.get("showRainbow") for beat in beats):
        fail("missing rainbow")
    paid = [item for item in shelf if item.get("number", 1) > 2]
    if any(item.get("free") for item in paid):
        fail("episodes after 2 should not be marked free")
    print(f"episode 1 ok: {len(beats)} beats, {total:.0f}s nominal")


if __name__ == "__main__":
    main()
