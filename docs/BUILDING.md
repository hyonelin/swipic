# Swipic 打包说明

## Android

本项目已验证 Flutter 3.47.3、Dart 3.13.3、OpenJDK 17、Android SDK 35/36 可以构建。

开发机一次性环境：

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export PATH="$JAVA_HOME/bin:$PATH"
flutter config --android-sdk /opt/homebrew/share/android-commandlinetools
flutter pub get
```

可直接安装的本地测试包：

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Play Console 上传包：

```bash
flutter build appbundle --release
```

产物路径：

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

当前 release 会回退到 debug signing，适合真机自测，不适合商店发布。正式发布前生成私有 keystore，并复制 `android/key.properties.example` 为 `android/key.properties` 后填写真实值。

生成 keystore 示例：

```bash
keytool -genkeypair -v \
  -keystore android/swipic-release.jks \
  -alias swipic \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

## iOS 自签名安装

iOS 需要完整 Xcode 和 CocoaPods。当前机器有 Xcode.app，但若 `flutter doctor` 报 Xcode incomplete，需要先运行：

```bash
sudo xcodebuild -license accept
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
brew install cocoapods
```

当前 Flutter 版本要求 iOS deployment target 至少为 15.0。

用免费 Apple ID 自签名安装到自己的 iPhone：

```bash
flutter pub get
open ios/Runner.xcworkspace
```

在 Xcode 中执行：

1. 选择 `Runner` target。
2. 打开 `Signing & Capabilities`。
3. 勾选 `Automatically manage signing`。
4. `Team` 选择你的 Apple ID Personal Team。
5. `Bundle Identifier` 改成全局唯一值，例如 `com.yourname.swipic`。
6. 连接 iPhone，选择真机，点击 Run。

免费 Apple ID 安装的 App 通常需要每 7 天重新签名；付费 Apple Developer 账号可以获得更完整的测试和分发能力。
