#!/usr/bin/env python3
"""Write Episode 1's data script. The JSON file is what the app loads."""
import json
from pathlib import Path

def line(hanzi, pinyin, english, spoken, speaker):
    return {"hanzi": hanzi, "pinyin": pinyin, "english": english, "spoken": spoken, "speaker": speaker}

def choice(cid, hanzi, pinyin, english, color, correct):
    return {"id": cid, "hanzi": hanzi, "pinyin": pinyin, "english": english, "color": color, "correct": correct}

Q = line("这是什么颜色？", "Zhè shì shénme yánsè?", "What color is this?", "这是什么颜色？", "panda")

def answer(hanzi, pinyin, english, spoken):
    return line(hanzi, pinyin, english, spoken, "animal")

beats = [
    {
        "id": "title", "kind": "title", "role": "title", "duration": 6, "hold": 3.2,
        "sfx": "pop", "color": "rainbow",
        "prompt": line("颜色", "Yánsè", "Colors", "颜色", "narrator"),
    },
    {
        "id": "hello", "kind": "dialogue", "role": "intro", "duration": 5, "hold": 0.8,
        "prompt": line("你好！", "Nǐ hǎo!", "Hello!", "你好！", "panda"),
    },
    {
        "id": "iam", "kind": "dialogue", "role": "intro", "duration": 5.5, "hold": 1.0,
        "prompt": line("我是小熊猫。", "Wǒ shì xiǎo xióngmāo.", "I'm Little Panda.", "我是小熊猫。", "panda"),
    },
    {
        "id": "q_red", "kind": "dialogue", "role": "question", "duration": 5.5, "hold": 0.6,
        "animal": "crab", "color": "red", "sfx": "boing", "prompt": Q,
    },
    {
        "id": "a_red", "kind": "dialogue", "role": "answer", "duration": 5.5, "hold": 1.1,
        "animal": "crab", "color": "red",
        "prompt": answer("它是红色的！", "Tā shì hóngsè de!", "It's red!", "它是红色的！"),
    },
    {
        "id": "q_yellow", "kind": "dialogue", "role": "question", "duration": 5.5, "hold": 0.6,
        "animal": "duck", "color": "yellow", "sfx": "boing", "prompt": Q,
    },
    {
        "id": "a_yellow", "kind": "dialogue", "role": "answer", "duration": 5.5, "hold": 1.1,
        "animal": "duck", "color": "yellow",
        "prompt": answer("它是黄色的！", "Tā shì huángsè de!", "It's yellow!", "它是黄色的！"),
    },
    {
        "id": "q_blue", "kind": "dialogue", "role": "question", "duration": 5.5, "hold": 0.6,
        "animal": "bird", "color": "blue", "sfx": "boing", "prompt": Q,
    },
    {
        "id": "a_blue", "kind": "dialogue", "role": "answer", "duration": 5.5, "hold": 1.1,
        "animal": "bird", "color": "blue",
        "prompt": answer("它是蓝色的！", "Tā shì lánsè de!", "It's blue!", "它是蓝色的！"),
    },
    {
        "id": "q_green", "kind": "dialogue", "role": "question", "duration": 5.5, "hold": 0.6,
        "animal": "frog", "color": "green", "sfx": "boing", "prompt": Q,
    },
    {
        "id": "a_green", "kind": "dialogue", "role": "answer", "duration": 5.5, "hold": 1.1,
        "animal": "frog", "color": "green",
        "prompt": answer("它是绿色的！", "Tā shì lǜsè de!", "It's green!", "它是绿色的！"),
    },
    {
        "id": "drill_cue", "kind": "dialogue", "role": "drill", "duration": 4.5, "hold": 0.7,
        "prompt": line("跟我读！", "Gēn wǒ dú!", "Read with me!", "跟我读！", "panda"),
    },
]

vocab = [
    ("v_red_1", "红", "hóng", "red", "red"),
    ("v_yellow_1", "黄", "huáng", "yellow", "yellow"),
    ("v_blue_1", "蓝", "lán", "blue", "blue"),
    ("v_green_1", "绿", "lǜ", "green", "green"),
    ("v_red_2", "红", "hóng", "red", "red"),
    ("v_yellow_2", "黄", "huáng", "yellow", "yellow"),
    ("v_blue_2", "蓝", "lán", "blue", "blue"),
    ("v_green_2", "绿", "lǜ", "green", "green"),
]
for vid, hz, py, en, color in vocab:
    beats.append({
        "id": vid, "kind": "vocab", "role": "vocab", "duration": 2, "hold": 1.05,
        "color": color, "sfx": "pop",
        "card": {"hanzi": hz, "pinyin": py, "english": en, "color": color},
        "prompt": line(hz, py, en, hz, "panda"),
    })

beats += [
    {
        "id": "joke_line", "kind": "joke", "role": "joke", "duration": 4.5, "hold": 0.5,
        "cans": "teeter",
        "prompt": line("哎呀！颜料倒下来啦！", "Āiyā! Yánliào dào xiàlái la!", "Oh no! The paint is falling!", "哎呀！颜料倒下来啦！", "panda"),
    },
    {
        "id": "joke_fall", "kind": "joke", "role": "joke", "duration": 6.5,
        "cans": "fall", "pandaMessy": True, "sfx": "splash", "color": "rainbow",
    },
    {
        "id": "rainbow", "kind": "joke", "role": "rainbow", "duration": 6, "hold": 1.8,
        "showRainbow": True, "pandaMessy": True, "color": "rainbow", "sfx": "ding",
        "prompt": line("哇！彩虹！", "Wa! Cǎihóng!", "Wow! A rainbow!", "哇！彩虹！", "panda"),
    },
    {
        "id": "your_turn", "kind": "dialogue", "role": "yourTurn", "duration": 5, "hold": 0.8,
        "sfx": "pop", "pandaMessy": True,
        "prompt": line("现在轮到你啦！", "Xiànzài lún dào nǐ la!", "Now it's your turn!", "现在轮到你啦！", "panda"),
    },
    {
        "id": "quiz_red", "kind": "quiz", "role": "quiz", "duration": 12, "quizPause": 3,
        "animal": "crab", "color": "red", "sfx": "boing", "pandaMessy": True,
        "prompt": Q,
        "answer": line("它是红色的！", "Tā shì hóngsè de!", "It's red!", "它是红色的！", "panda"),
        "choices": [
            choice("red", "红", "hóng", "red", "red", True),
            choice("yellow", "黄", "huáng", "yellow", "yellow", False),
            choice("blue", "蓝", "lán", "blue", "blue", False),
        ],
    },
    {
        "id": "quiz_twist", "kind": "quiz", "role": "quiz", "duration": 12, "quizPause": 3,
        "twist": True, "animal": "duck", "color": "yellow", "sfx": "boing", "pandaMessy": True,
        "prompt": line("是蓝色的吗？", "Shì lánsè de ma?", "Is it blue?", "是蓝色的吗？", "panda"),
        "answer": line("它是黄色的！", "Tā shì huángsè de!", "It's yellow!", "它是黄色的！", "panda"),
        "correction": line("不是。它是黄色的！", "Bú shì. Tā shì huángsè de!", "No. It's yellow!", "不是。它是黄色的！", "panda"),
        "choices": [
            choice("blue", "蓝", "lán", "blue", "blue", False),
            choice("yellow", "黄", "huáng", "yellow", "yellow", True),
            choice("red", "红", "hóng", "red", "red", False),
        ],
    },
    {
        "id": "quiz_green", "kind": "quiz", "role": "quiz", "duration": 12, "quizPause": 3,
        "animal": "frog", "color": "green", "sfx": "boing", "pandaMessy": True,
        "prompt": Q,
        "answer": line("它是绿色的！", "Tā shì lǜsè de!", "It's green!", "它是绿色的！", "panda"),
        "choices": [
            choice("blue", "蓝", "lán", "blue", "blue", False),
            choice("green", "绿", "lǜ", "green", "green", True),
            choice("yellow", "黄", "huáng", "yellow", "yellow", False),
        ],
    },
    {
        "id": "bye", "kind": "outro", "role": "outro", "duration": 5, "hold": 1.4,
        "pandaMessy": True,
        "prompt": line("再见！", "Zàijiàn!", "Bye-bye!", "再见！", "panda"),
    },
    {
        "id": "bye2", "kind": "outro", "role": "outro", "duration": 5, "hold": 1.6,
        "pandaMessy": True, "sfx": "pop",
        "prompt": line("下次见！", "Xià cì jiàn!", "See you next time!", "下次见！", "panda"),
    },
]

episode = {
    "id": "colors",
    "number": 1,
    "titleHanzi": "颜色",
    "titlePinyin": "Yánsè",
    "titleEnglish": "Colors",
    "free": True,
    "beats": beats,
}
total = sum(b["duration"] for b in beats)
print("beats", len(beats), "duration", total)
out = Path(__file__).resolve().parents[1] / "LittlePandaChinese/Resources/Episodes/episode-01-colors.json"
out.write_text(json.dumps(episode, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(out)
