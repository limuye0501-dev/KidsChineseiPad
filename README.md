# Little Panda Chinese

iPad-first SwiftUI stories that teach Mandarin to children aged 3–6. The app also runs on iPhone, in landscape. Episode 1, **颜色 Colors**, is a short paper-cut episode: a panda asks what color an animal is, four colors answer, a vocab pop drill, a paint-can joke that becomes a rainbow, then a tap-to-answer quiz.

The player is a timeline. Another episode is a JSON script in `LittlePandaChinese/Resources/Episodes/`, plus a shelf row in `catalog.json`.

## Build

```bash
brew install xcodegen && xcodegen generate && open LittlePandaChinese.xcodeproj
```

Run the **LittlePandaChinese** scheme on an iPad simulator. The scheme’s StoreKit file unlocks the local **Unlock All** purchase. That product is not created in App Store Connect.

CI (`.github/workflows/build.yml`) builds for the iOS simulator and runs the timeline tests. TestFlight (`.github/workflows/testflight.yml`) archives on `macos-15-intel` with the same ASC API key secrets as Every Second Pays. The build number is the workflow run number plus 9.

## Rename

Change `BUNDLE_ID` and `DEVELOPMENT_TEAM` in `project.yml`, and `CFBundleDisplayName` in `LittlePandaChinese/Info.plist`. The widget-less bundle id is `com.limuye.littlepandachinese`.

## What’s in Episode 1

- 红 hóng, 黄 huáng, 蓝 lán, 绿 lǜ, then 彩虹 cǎihóng
- Pattern: 这是什么颜色？ / 它是红色的！
- Quiz pause is 3 seconds, then a check and a ding, or the scripted twist 是蓝色的吗？ with an X and 不是。它是黄色的！
- Stars (1–3) stay on the device

## Audio

Spoken Chinese uses the on-device `zh-CN` voice behind `AudioProvider`. Recorded lines replace it by filename. See `LittlePandaChinese/Resources/VoiceOver/README.md`. Music and sound effects are synthesized placeholders (ukulele/xylophone loop, pop, boing, splash, ding).

## Kids Category

No ads, no third-party analytics, no accounts, and no links out of the app. Settings and the Unlock All purchase sit behind a hold-to-confirm math question. Episodes 1 and 2 are free; later episodes use a one-time non-consumable. Progress never leaves the iPad.

## Layout

- `LittlePandaChinese/Engine` script, timeline, and the step-through session
- `LittlePandaChinese/Views` paper-cut stage (SwiftUI tweens, SpriteKit paint splash)
- `LittlePandaChinese/Audio` voice, music, and effects
- `LittlePandaChineseTests` timeline, quiz grading, stars, and the free/locked shelf
