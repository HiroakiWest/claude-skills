# claude-skills

HiroakiWest の Claude Code 用スキル集です。このリポジトリ自体が
プラグインマーケットプレイス `west-skills` で、プラグイン `west` を1つ含みます。

## インストール

Claude Code の中で:

```
/plugin marketplace add HiroakiWest/claude-skills
/plugin install west@west-skills
```

シェルから:

```
claude plugin marketplace add HiroakiWest/claude-skills
claude plugin install west@west-skills
```

確認: Claude Code で `/west:check` と打つと、ホスト名つきで `west-skills OK` が返ります。

## 更新

```
/plugin marketplace update west-skills
```

起動時に自動で更新したい場合は、`/plugin` → Marketplaces → `west-skills` で
自動更新を有効にします(Anthropic 以外のマーケットプレイスは既定で無効)。

## スキルの追加

`skills/<スキル名>/SKILL.md` を置くだけで、`west:<スキル名>` として読み込まれます。

```
skills/
  check/
    SKILL.md
```

公開リポジトリなので、ホスト名・IP・内部ドメイン・パス・メールアドレス・
トークンなど環境固有の情報は書かないでください。環境依存の部分は各ホストの
`~/.claude/skills/` や CLAUDE.md に置きます。

追加・変更したら push 前に検証します:

```
claude plugin validate .
```

## ライセンス

MIT
