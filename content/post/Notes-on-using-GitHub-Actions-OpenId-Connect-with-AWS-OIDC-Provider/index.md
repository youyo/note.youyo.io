---
title: 'GitHub Actions OpenId ConnectでAWS OIDC Providerと連携するときの注意点'
date: 2022-08-23T15:09:38+09:00
tags: [AWS,GitHubActions]
summary: GitHubActions最高
pin: false
draft: false
---

## ざっと手順

- [プロバイダーとIAMロールを作成するCFn](https://github.com/aws-actions/configure-aws-credentials#sample-iam-role-cloudformation-template)をデプロイする
- action.ymlを作成する

## 注意点

- GitHub Actionsのdefault permissionに `id-tokens: write` が含まれていないので忘れずに追加する

```yaml
on:
  push:
    branches:
      - main

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v3
        with:
          python-version: "3.8"
      - uses: aws-actions/setup-sam@v2
      - uses: aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: arn:aws:iam::111111111111:role/my-github-actions-role-test
          aws-region: us-east-2
      - run: sam build --use-container
      - run: sam deploy --no-confirm-changeset --no-fail-on-empty-changeset
```

## Ref
- https://tech.guitarrapc.com/entry/2021/11/05/025150#GitHub-Actions%E3%81%A7%E5%AE%9F%E8%A1%8C%E3%81%97%E3%81%A6%E3%81%BF%E3%81%9F%E3%82%89%E5%8B%95%E4%BD%9C%E3%81%97%E3%81%AA%E3%81%84
- https://github.com/aws-actions/configure-aws-credentials  
Usageにちゃんと書いてた..