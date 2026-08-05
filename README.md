# triggers

GitHub Actionsを実行基盤として、submoduleで参照している各リポジトリの定期処理を起動・永続化するリポジトリです。

## Submodules

| パス | リポジトリ | 用途 |
|---|---|---|
| `osoba` | `shamaton/osoba` | 売買代金ランキングの生成・確認 |
| `th` | `shamaton/threads` | Threads投稿データの生成・投稿 |

submoduleを対象ブランチの最新へ更新するには、次を実行します。

```sh
make update-osoba
make update-threads
```

## Otoriyose workflows

### 投稿データ生成

`.github/workflows/generate-oto.yml` を手動実行します。

1. `threads/main` の最新状態を `th` へcheckoutする
2. 楽天の商品情報から指定日・指定件数の投稿JSONを生成する
3. `threads` に `automation/otoriyose-*` ブランチを作成する
4. 投稿データをcommit・pushする
5. `threads` にレビュー用Pull Requestを作成する

Pull Requestのレビューとマージを投稿承認として扱います。未レビューの生成PRが残っている場合、新しい生成ワークフローは重複候補を避けるため停止します。

入力値：

- `target_date`: JSTの対象日。`YYYY-MM-DD`。省略時はJST当日
- `count`: 生成件数。1〜30、既定値3

### 投稿

`.github/workflows/publish-oto.yml` を手動実行します。

1. `threads/main` の最新状態を `th` へcheckoutする
2. キュー先頭の投稿または返信を `in_flight` にする
3. `in_flight` を `threads/main` へcommit・pushする
4. 商品情報を再検証してThreads APIへ投稿する
5. 成否にかかわらず投稿状態を `threads/main` へcommit・pushする
6. 親投稿に返信がある場合は、返信の `in_flight` と親の成功状態を同じcommitで保存してから返信を投稿する
7. `triggers` のsubmodule参照を最新の永続化済みSHAへ更新する

同一アカウントの投稿は `threads-otoriyose-publish` concurrency groupで直列化し、実行中のジョブはキャンセルしません。APIの結果が不明な場合は `unknown` を保存し、自動再送しません。

スケジュール実行は本番・障害試験が完了するまで有効化しません。

## Required GitHub Actions secrets

### Repository access

- `TRIGGERS_REPO_PAT`
  - `shamaton/threads` のContents書き込み
  - `shamaton/threads` のPull requests書き込み
  - 対象リポジトリを限定したfine-grained PATまたはGitHub App tokenを使用する

### Rakuten API

- `R_APP_ID`
- `R_AFF_ID`
- `R_ACCESS_KEY`（投稿データ生成時に使用）
- `R_HTTP_REFERER`（投稿データ生成時に使用。楽天に登録したドメイン）

### Threads API

- `TH_OTO_ACCESS_TOKEN`
- `TH_CLIENT_ID`
- `TH_CLIENT_SECRET`
- `TH_REDIRECT_URI`

`generate-oto.yml` には楽天APIのSecretだけを渡し、Threads APIのSecretは渡しません。`R_ACCESS_KEY` と `R_HTTP_REFERER` はランキングAPIを利用する投稿データ生成で必須です。

## Apps Script dispatch

`app.gs` はGitHub Actionsの `workflow_dispatch` を外部スケジュールから起動するための関数を提供します。

- `dispatchUpdateOsobaWorkflow`
- `dispatchCheckOsobaWorkflow`
- `dispatchGenerateOtoriyoseWorkflow`
- `dispatchPublishOtoriyoseWorkflow`

Apps ScriptのScript Propertiesに、`shamaton/triggers` のActions workflowを実行できる `GITHUB_TOKEN` を設定します。
