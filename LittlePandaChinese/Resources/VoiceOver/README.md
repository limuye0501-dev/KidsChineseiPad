# Final voice-over and music

Episode playback speaks Chinese through `AVSpeechSynthesizer` (`zh-CN`) until a
recording is in the app bundle. Drop replacements anywhere under
`LittlePandaChinese/` so XcodeGen copies them to the bundle root:

| File | Replaces |
| --- | --- |
| `vo_<beatID>.m4a` | That beat's spoken line. Example: `vo_q_red.m4a` is 「这是什么颜色？」 |
| `vo_<beatID>_feedback.m4a` | The quiz reveal. Example: `vo_quiz_twist_feedback.m4a` is 「不是。它是黄色的！」 |
| `music_ukulele_loop.m4a` | The synthesized ukulele/xylophone loop |

`.caf` and `.wav` are also accepted for voice files. Spoken text is Chinese only.
Pinyin and the English gloss stay on screen.

Beat ids for Episode 1 (`颜色`):

`title`, `hello`, `iam`, `q_red`, `a_red`, `q_yellow`, `a_yellow`, `q_blue`,
`a_blue`, `q_green`, `a_green`, `drill_cue`, `v_red_1`, `v_yellow_1`, `v_blue_1`,
`v_green_1`, `v_red_2`, `v_yellow_2`, `v_blue_2`, `v_green_2`, `joke_line`,
`rainbow`, `your_turn`, `quiz_red`, `quiz_twist`, `quiz_green`, `bye`, `bye2`

`joke_fall` has no line. Quiz feedback ids are `quiz_red_feedback`,
`quiz_twist_feedback`, and `quiz_green_feedback`.

Pop, boing, splash, ding, and the soft wrong-answer tone are synthesized in
`AudioEngine.swift` until you want to replace those too.
