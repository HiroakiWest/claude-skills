# claude-skills

HiroakiWest の Claude Code 用スキル集です。このリポジトリ自体がプラグインマーケットプレイス
`west-skills` になっていて、次の4つのプラグインを配っています。

| プラグイン | 内容 | 取得元 |
|---|---|---|
| `west` | 自作スキル(今は動作確認用の `/west:check` だけ) | このリポジトリ |
| `agent-skills` | 仕様・計画・TDD・デバッグ、アクセシビリティ、API設計、CI/CD、性能、可観測性、セキュリティ設計、リリース準備など | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) から一部だけ取り込み(`plugins/agent-skills/`) |
| `ponytail` | 最小限の変更で済ませる「lazy senior dev」モード、レビュー・監査 | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)(v5.3.3 のコミットに固定) |
| `context7` | ライブラリの最新ドキュメントを引く MCP サーバ | [upstash/context7](https://github.com/upstash/context7)(コミットに固定) |

あわせて、公式マーケットプレイス(`claude-plugins-official`)の `hookify` と `security-guidance` も入れます。
[graphify](https://github.com/safishamsi/graphify) はプラグイン形式で配布されていないので、別の手順で入れます。

選ぶ基準は「機能が重ならないこと」と「トークンを無駄に使わないこと」です。測った結果は
下の「トークン消費の目安」にあります。

## 前提

- Claude Code 2.1 系の新しめの版
- ponytail を使うホスト: Node.js が PATH にあること(フックが Node で動きます)
- hookify・security-guidance を使うホスト: python3
- graphify を使うホスト: [uv](https://docs.astral.sh/uv/)(Python 3.11.5 以上が無ければ uv が自動で用意します)

## インストール(ホストごとに1回)

Claude Code の中で、**1行ずつ別々に**送ってください(まとめて送ると2行目が失敗することがあります)。

```
/plugin marketplace add HiroakiWest/claude-skills
/plugin install west@west-skills
/plugin install agent-skills@west-skills
/plugin install ponytail@west-skills
/plugin install context7@west-skills
/plugin install hookify@claude-plugins-official
/plugin install security-guidance@claude-plugins-official
```

シェルからでも同じことができます。

```
claude plugin marketplace add HiroakiWest/claude-skills
for p in west agent-skills ponytail context7; do claude plugin install "$p@west-skills"; done
for p in hookify security-guidance; do claude plugin install "$p@claude-plugins-official"; done
```

security-guidance の LLM レビューは切っておきます(理由は下の「トークン消費の目安」)。
`~/.claude/settings.json` に次を足してください(`env` がすでにあれば、その中に1行足します)。

```json
"env": { "ENABLE_CODE_SECURITY_REVIEW": "0" }
```

入れ終わったら Claude Code を起動し直して、`/west:check` で確認します
(`west-skills OK: <ホスト名>` が返れば成功です)。`/plugin` の Installed でも一覧を確認できます。

### graphify(別途インストール)

```
uv tool install graphifyy     # パッケージ名は y が2つ。コマンド名は graphify
graphify install              # Claude Code 用のスキルを登録
```

使うときは、プロジェクトのディレクトリで `/graphify .` と打ちます。
特定のプロジェクトで常に graph を使わせたい場合は、そのディレクトリで `graphify claude install` も実行します
(下の「graphify はグローバル設定を書き換える」を参照)。

## 更新

```
/plugin marketplace update west-skills
```

更新後は Claude Code を起動し直します。

- Anthropic 以外のマーケットプレイスは、既定では自動更新がオフです。起動時に自動で更新したい場合は、
  `/plugin` → Marketplaces → `west-skills` で自動更新を有効にします。
- `west` と `agent-skills` には version を書いていません。そのため、このリポジトリに push するたびに
  新しい版として扱われます。
- `ponytail` と `context7` は、外部リポジトリをコミット SHA で固定しています。タグは後から付け替えられるので、
  `ref` だけでなく `sha` も指定しています。版を上げるときは、upstream の変更内容を確認してから、
  `marketplace.json` の `ref` と `sha` を書き換えて push します。SHA は次のコマンドで確認できます。

  ```
  git ls-remote https://github.com/DietrichGebert/ponytail.git refs/tags/<タグ>
  git ls-remote https://github.com/upstash/context7.git refs/heads/master
  ```
- graphify は `uv tool upgrade graphifyy` のあと `graphify install` をもう一度実行します。

## トークン消費の目安

1セッションあたりの概算です(2026-11 時点)。「常時」はスキルやエージェントの説明文です。
「差し込み」は、フックがセッション開始時などに会話へ足す文章です。`claude plugin details` は
フックの差し込みを数えないので、フックを実際に動かして測りました。

| プラグイン | 常時 | 差し込み | 使ったときだけかかるもの |
|---|---|---|---|
| west | ほぼ 0 | 0 | — |
| agent-skills | 約1,900 | 0 | 該当する作業で本文を読み込む(1回 2〜5千) |
| ponytail | 約430 | 開始時 約1,360、サブエージェント起動ごとに 約750 | 返答と変更を短くする方向に働く(作者の計測ではコスト -42〜75%、自己申告) |
| context7 | ほぼ 0(ツールは使うときに読み込み) | 0 | 問い合わせごとにドキュメント数千 |
| hookify | 約220 | 0(自分で作ったルールに一致したときだけ) | ルール作成時 |
| security-guidance(LLM レビュー切り) | 0 | 危険なパターンに一致したときの警告文だけ | — |
| graphify | 約150 | 0 | `/graphify` 実行時(コード以外の解析は LLM を使うので重い) |

### 評価して入れなかったもの

| プラグイン | 理由 |
|---|---|
| superpowers | 常時 約700+開始時の差し込み 約900。さらに「設計 → 計画 → サブエージェントで実装 → レビュー2回」の手順を毎回踏ませるので、総トークンが数倍になりやすい。最小限にする ponytail とも方針が逆。必要な手順(仕様・計画・TDD・デバッグ)は agent-skills で代わりにする |
| security-guidance の LLM レビュー(既定) | 毎ターンの終わりに Opus で diff をレビューし、コミットのたびにエージェントでもレビューする。実測では41回で入力 約50万トークン(1回で入力 8.6万・出力 27 の回もあった)。`ENABLE_CODE_SECURITY_REVIEW=0` で切り、パターン警告だけ残す。必要なときは組み込みの `/security-review` を使う |
| claude-security | 常時 約610(エージェント9個分の説明文)。スキャンは複数エージェントで非常に重い。組み込みの `/security-review` と役割が重なる |
| explanatory-output-style | 開始時に 約330 を差し込み、毎回の返答に解説ブロックを付けさせる。出力を増やすこと自体が目的の機能 |

## 注意点

### 同じものを二重に入れない

以下はほかのマーケットプレイスにも同じものがあります。両方入れるとスキルやフックが二重に動くので、
ここの版だけにしてください。すでに入っている場合は先に外します。

| ここの版 | 外すもの |
|---|---|
| `agent-skills@west-skills` | `agent-skills@addy-agent-skills` |
| `ponytail@west-skills` | `ponytail@ponytail` |
| `context7@west-skills` | `context7@claude-plugins-official`、または `claude mcp add` で直接入れた context7 |

`/plugin uninstall <名前>@<マーケットプレイス>` で外せます。

### agent-skills で取り込んでいないもの

次のスキル・コマンド・エージェントは、Claude Code 組み込みコマンド・context7・ponytail と役割が重なるか、
発火しすぎてトークンを食うので取り込んでいません。代わりに右の欄のものを使います。

| 取り込んでいないもの | 理由・代わりに使うもの |
|---|---|
| idea-refine, interview-me | `spec-driven-development` と役割が重なる |
| incremental-implementation | 「複数ファイルに触れる変更すべて」で発火して毎回 約2,400 を読み込む。小さく進めるのは ponytail が担う |
| git-workflow-and-versioning | 「あらゆるコード変更」で発火して毎回 約3,600 を読み込む |
| code-review-and-quality, doubt-driven-development, `/review`, code-reviewer | `/code-review`、`/ponytail-review` |
| code-simplification, `/code-simplify` | `/simplify`、ponytail |
| source-driven-development | context7 |
| browser-testing-with-devtools | Claude in Chrome(Chrome DevTools MCP 前提のため) |
| using-agent-skills | スキルの振り分け役。無くても各スキルは説明文で発火する |
| `/spec`, `/plan`, `/build`, `/test`, `/ship`, test-engineer, security-auditor | スキル本体だけで足りる。`/ship` の代わりは `/code-review` と `/security-review` |

`test-driven-development` は「ロジックを書くとき全般」で発火する書き方なので、読み込みが多すぎるようなら外します。

取り込み直すときは `scripts/sync-agent-skills.sh [ref]` を実行します。upstream に新しいスキルが
増えていると「未分類の新しいスキル」と表示されるので、スクリプト先頭の一覧のどちらかに足してください。

### ponytail は常時オン

- 既定で毎セッション `full` モードが自動で有効になり、「最小限の変更」を強く促します。
  - その場だけ止める: 「stop ponytail」と言うか `/ponytail off`
  - 既定を弱める: `~/.config/ponytail/config.json` に `{ "defaultMode": "lite" }`、
    または環境変数 `PONYTAIL_DEFAULT_MODE=lite`
- フック(SessionStart / SubagentStart / UserPromptSubmit)が外部リポジトリの Node コードを毎回実行します。
  これが版を固定している理由です。版を上げる前に、upstream の変更内容を確認してください。
- インストール時に設定項目(userConfig)を聞かれます。既定のままで問題ありません。
  - 作業記録は手元の `~/.config/ponytail/band/` に CSV で残ります(`ledger`、既定オン)。
  - webhook の URL を空のままにしておけば、外部には何も送られません。
  - 後から変えるときは `/plugin configure ponytail@west-skills` を使います。

### context7 は外部サービスに問い合わせる

- context7.com のサーバに、ライブラリ名や調べたい内容が送られます。社外秘のコードや名前を
  問い合わせに含めないようにしてください。
- 匿名でも使えますが、回数制限があります。足りなくなったら、案内に従って Context7 の認証を行います。

### graphify はグローバル設定を書き換える

- `graphify install` を実行すると、`~/.claude/skills/graphify/` が作られ、`~/.claude/CLAUDE.md` に
  `/graphify` の呼び出し方が追記されます(ファイルがなければ新規作成)。`~/.claude/settings.json` は変更されません。
- プロジェクトのディレクトリで `graphify claude install` を実行すると、そのプロジェクトの `CLAUDE.md` に節が追加されます。
  さらに `.claude/settings.json` に、Grep・Read・Glob の前に graph を使うよう促すフックが登録されます。
  `--strict` を付けると、graph を調べる前の Read・Grep が拒否されるようになります。
- `.claude/settings.json` を git 管理しているプロジェクトでは、このフックもコミットされることに注意してください。
- グラフは各プロジェクトの `graphify-out/` に出力されます。git に入れない場合は `.gitignore` に足します。
- 外すときは `graphify uninstall`(`--purge` を付けると `graphify-out/` も消えます)。

### claude.ai 側のスキルとの関係

claude.ai の設定で有効にしたスキル(pdf, docx, xlsx など)は、アカウント単位で各ホストに自動同期され、
`anthropic-skills:〜` として見えます。このリポジトリとは別の仕組みです。同じものをここに入れる必要はありません。

## スキルの追加

自作スキルは `skills/<スキル名>/SKILL.md` に置くと、`west:<スキル名>` として読み込まれます。

公開リポジトリなので、ホスト名・IP・内部ドメイン・パス・メールアドレス・トークンなど、
環境固有の情報は書かないでください。環境に依存する部分は、各ホストの `~/.claude/skills/` や CLAUDE.md に置きます。

push する前に、ルートで検証を通します。

```
claude plugin validate .
```

## ライセンス

- このリポジトリ: MIT(`LICENSE`)
- `plugins/agent-skills/`: upstream の MIT ライセンス(`plugins/agent-skills/LICENSE`、Copyright Addy Osmani)
- ponytail・context7・graphify はそれぞれの取得元のライセンスに従います(ここには同梱していません)
