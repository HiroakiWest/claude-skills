# agent-skills(抜粋版)

[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)(MIT License)から、
Claude Code 組み込みコマンド・context7・ponytail と機能が重ならず、トークン消費の小さい部分だけを
取り込んだものです。取り込んだ upstream のコミットは `UPSTREAM` に記録しています。
ファイルの中身は upstream のまま変更していません。著作権表示は `LICENSE` のとおりです。

更新はリポジトリのルートで `scripts/sync-agent-skills.sh` を実行します。
取り込む・除外するスキルの一覧はこのスクリプトの先頭にあります。
