---
title: curlの`--aws-sigv4`オプションでLambdaの認証付きURLにリクエストする
date: 2022-05-24T11:00:00+09:00
tags: [AWS]
summary: $(brew --prefix)を置き換えたら高速化した
pin: false
draft: false
---

AWS Lambdaの関数URLを有効にする際、IAM認証とすることがほとんどかと思います。  
ただそういった場合でも気軽に`curl`でリクエストを送ることができるとテストが楽です。  
そんなときに `--aws-sigv4` オプションを利用すると便利です。

- 認証情報なしリクエスト

403が返る

```
$ curl -s https://****.lambda-url.ap-northeast-1.on.aws/
{"Message":"Forbidden"}
```

- 認証情報つきリクエスト

200が返る :)

```
$ curl -s https://****.lambda-url.ap-northeast-1.on.aws/ \
-H "X-Amz-Security-Token: ${AWS_SESSION_TOKEN}" \
--aws-sigv4 "aws:amz:ap-northeast-1:lambda" \
--user "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}"
"Hello from Lambda!"
```

参考にした記事。  
ref: https://gist.github.com/mryhryki/28fcd54e8a8cdffb78462d171ce48b27