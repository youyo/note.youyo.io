---
title: AWS CodeCommitへ同期を行うGitHub Actionsを作成した
date: 2021-06-22T10:10:00+09:00
tags: [AWS,CodeCommit,GitHubActions]
summary: 'https://github.com/marketplace/actions/sync-up-to-aws-codecommit-action'
pin: false
draft: false
---

## なぜ作成したか

- CodeCommitは個人的には使いづらいのでGitHubから同期してくれれば解決しそう
	- 複数repositoryを扱う際に `~/.ssh/config` ファイルを編集して `Host` を設定してそれをgit configに利用するあたり使いづらい
```bash
Host example-host
  Hostname git-codecommit.ap-northeast-1.amazonaws.com
  User EXAMPLEUSERID
```
```
[remote "origin"]
	url = ssh://example-host/v1/repos/example-repo
	fetch = +refs/heads/*:refs/remotes/origin/*
```

- IAM Userを作成して公開鍵を登録したりという準備
	- そもそもIAM Userを作成したくないしAssumeRole後のIAM Roleから利用したい

## そもそもIAM Roleでアクセスできないのか？

できました。  
https://docs.aws.amazon.com/ja_jp/codecommit/latest/userguide/setting-up-https-unixes.html  
  
重要なポイントは下記。

- 認証情報ヘルパーを設定する
```
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true
```

- (個人的に)`[credential]`でグローバルに設定されることに抵抗があるので下記のようにURLで縛っておく
```
[credential "https://git-codecommit.*.amazonaws.com"]
```

- macOSの場合`osxkeychain`によるキャッシュを無効にしておく
	- デフォルトで有効になっている`osxkeychain`のキャッシュをそのままにしておくと、例えばCodeCommitへのアクセスにAssumeRole API Callで得られた認証情報を利用しているときにその認証情報がexpireした後もキャッシュし続けてしまうためそれ以降403エラーが出てしまう
	- 対応方法: https://docs.aws.amazon.com/ja_jp/codecommit/latest/userguide/troubleshooting-ch.html#troubleshooting-macoshttps

IAM Roleでのアクセスが実現できました。

## IAM RoleでCodeCommitへのアクセスができるようになって問題解決したけどせっかくなのでGitHub->CodeCoomitなアクションを作成した

- https://github.com/marketplace/actions/sync-up-to-aws-codecommit-action

## 使い方

```yaml
name: sync up to codecommit

on:
  push:
    tags-ignore:
      - '*'
    branches:
      - '*'

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.TEST_AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.TEST_AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Sync up to CodeCommit
        uses: youyo/sync-up-to-codecommit-action@v1
        with:
          repository_name: test_repo
          aws_region: us-east-1
```

作ってみたけど現状使ってはいない。
