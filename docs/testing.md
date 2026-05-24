# テストとTestFlight配布手順

このリポジトリは、Unit Testでロジックを確認し、XcodeからTestFlightへアップロードして自分と友人のiPhoneで実機QAする前提です。

## ローカル確認

MacとXcodeがある環境では、次のコマンドでビルドとUnit Testを確認します。

```sh
DEVICE_ID="$(xcrun simctl list devices available | awk -F'[()]' '/^-- iOS / { ios = 1; next } /^--/ { ios = 0 } ios && /\([0-9A-F-]{36}\)/ { print $2; exit }')"

xcodebuild test \
  -project ChargeReminder.xcodeproj \
  -scheme ChargeReminder \
  -destination "platform=iOS Simulator,id=${DEVICE_ID}" \
  -derivedDataPath /tmp/charge-reminder-dd \
  CODE_SIGNING_ALLOWED=NO
```

シミュレータが見つからない場合は、`xcodebuild -downloadPlatform iOS` でiOS Simulatorランタイムを追加してから再実行します。

## GitHub Actions

`.github/workflows/ios-ci.yml` は、`main` へのpushとPull RequestでUnit Testを実行します。

TestFlightへのアップロードは、現時点ではGitHub Actionsでは自動化せず、Xcodeの `Archive` から手動で行います。CI上で安定して自動アップロードするには、Distribution証明書、Provisioning Profile、CI用keychainの管理が必要になり、初期テスト目的には運用コストが高いためです。

## Xcode署名設定

Apple Developer Program登録済みのApple AccountでXcodeへログインした後、次を確認します。

1. `Xcode > Settings > Accounts` を開く。
2. Apple Accountを選択する。
3. 対象Teamを選択し、`Manage Certificates...` を開く。
4. `+` から `Apple Development` を作成する。
5. TestFlightへアップロードする場合は、必要に応じて `Apple Distribution` も作成する。

ターミナルで次を実行し、署名IDが表示されればローカル署名の準備は完了です。

```sh
security find-identity -v -p codesigning
```

Xcodeで実機に直接インストールする場合は、対象iPhoneをUSB接続または同一ネットワークで認識させ、`Signing & Capabilities` でTeamを選びます。

## TestFlightアップロード

TestFlight用ビルドは、Xcodeから手動でアップロードします。

1. Xcodeで `ChargeReminder.xcodeproj` を開く。
2. Schemeに `ChargeReminder`、実行先に `Any iOS Device (arm64)` または接続中の実機を選ぶ。
3. `Product > Archive` を実行する。
4. Organizerで作成されたArchiveを選び、`Distribute App` を押す。
5. `App Store Connect` への配布を選び、画面の指示に従ってアップロードする。
6. App Store ConnectのTestFlightタブで、アップロードしたビルドが処理完了になるまで待つ。

新しいビルドを再アップロードする場合は、XcodeのBuildを前回より大きい値に上げてからArchiveします。

## App Store Connect初期設定

1. Apple Developer Programに加入したApple AccountでApp Store Connectを開く。
2. Bundle ID `com.cloford.chargereminder` を使ってiOSアプリレコードを作る。
3. App情報、カテゴリ、連絡先、輸出コンプライアンスの必要項目を入力する。
4. TestFlightタブでテスト情報を入力する。
5. 外部テスター用グループを作る。
6. 初回ビルドをグループへ追加し、Beta App Reviewに進める。
7. 承認後、自分と友人のApple IDメールアドレスを外部テスターに追加するか、公開リンクを共有する。

外部テスター向けの初回ビルドはBeta App Reviewが必要です。承認後はTestFlightアプリからインストールできます。

## 実機QAチェックリスト

| 項目 | 期待結果 |
|---|---|
| TestFlightインストール | 自分と友人のiPhoneへインストールできる |
| 初回起動 | アプリがクラッシュせず4タブが表示される |
| 通知許可 | 通知許可ダイアログが表示され、許可/拒否後の表示が破綻しない |
| 通知予約 | 数分後の時刻に変更するとローカル通知が届く |
| 通知ON/OFF | OFFの通知は届かず、ONへ戻すと予約される |
| 通知から起動 | 通知をタップして起動してもクラッシュしない |
| 通知から確認履歴 | 通知をタップしてアプリに戻ると、履歴に「通知から確認」として記録される |
| 手動更新履歴 | ホーム右上の更新ボタン、または引っ張って更新で「手動更新」として記録される |
| 自動更新履歴 | アプリ起動・復帰時に必要に応じて「自動更新」として記録される |
| 履歴の重複抑制 | 同一状態の自動更新が短時間で何件も増えない |
| 履歴の表示順 | 履歴タブでは新しい確認が上に表示される |
| バッテリー表示 | 残量が「約xx%」で表示され、端末状態と大きく矛盾しない |
| 充電状態 | 「未接続」「充電中」「充電完了」が実機状態に合う |
| モバイルバッテリー | モバイルバッテリー接続/解除で状態が更新される |
| 推奨表示 | 充電推奨ライン変更と充電状態に応じて「安全」「注意」「充電推奨」が変わる |
| 復帰時更新 | バックグラウンドから戻ると状態が更新される |
| 集中モード/通知OFF | iOS側で通知が抑制されてもアプリは仕様どおり動作する |

## 通知タップクラッシュの再確認

今回の修正で最優先に再確認するケースです。

1. 通知時刻を1分後に設定し、アプリを終了せず待つ。
2. 通知を確認し、通知一覧からタップしてアプリに戻る。
3. クラッシュしないことを確認する。
4. 履歴に「通知から確認」として記録されることを確認する。
5. 通知時刻を10分後に設定し、アプリをタスクキルして待つ。
6. 通知タップで起動してクラッシュしないことを確認する。
7. 通知一覧に残った通知を再度タップしてもクラッシュしないことを確認する。

## 既知の制約

- iOSの制約上、バックグラウンドで常時バッテリー監視はしません。
- ローカル通知は通知許可、集中モード、iOS通知設定に依存します。
- バッテリー残量はiOSが返す値を表示するため、端末によって5%刻みのように見える場合があります。
- TestFlightの外部テスターは最大10,000人、内部テスターは最大100人です。
- TestFlightビルドはアップロードから最大90日間テストできます。
