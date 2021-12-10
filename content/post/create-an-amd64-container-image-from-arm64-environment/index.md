---
title: arm64環境(Appleシリコン)からamd64(x86_64)なコンテナイメージを作成する
date: 2021-12-10T12:00:00+09:00
tags: [AWS,Fargate,Docker,container]
summary: Intel processorなEC2上でdockerdを外部公開して、そこへ接続してdocker build.
pin: false
draft: false
---

## 手元のMBPで作成したコンテナイメージがFargateで動かない

>exec user process caused: exec format error

以下のブログの通りで、arm64環境で作成したコンテナイメージはFargate(x86_64)では動きませんでした。

https://nomad.office-aship.info/ecs-format-error/

## どうやってamd64(x86_64)なコンテナイメージを作成するか？

いろいろ考えた結果、Intel processorなEC2上でdockerdを外部公開してそこへ接続してdocker buildを行うのが一番手っ取り早そうだなと思いました。  
以下docekrdの外部公開手順です。こちらのgistが参考になりました。

https://gist.github.com/styblope/dc55e0ad2a9848f2cc3307d4819d819f

```bash
$ sudo echo '{"hosts": ["tcp://0.0.0.0:2375", "unix:///var/run/docker.sock"]}' > /etc/docker/daemon.json
$ sudo systemctl restart docker.service
```

これで `0.0.0.0:2375` で公開されました。  
あとはクライアント実行時に接続先を指定するだけでokです。

```bash
// 環境変数か -H で指定
// $ docker -H 'tcp://remote-host:2375' node ls
// or
// $ export DOCKER_HOST='tcp://remote-host:2375'
// $ docker node ls

$ docker -H 'tcp://remote-host:2375' node ls
ID                            HOSTNAME              STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
yycg26no9amzbwe395fnkm62e *   remote-host           Ready     Active         Leader           17.06.2-ce
```

## そういえば

FargateがARM64をサポートしたけども、手元の環境にFargateをホイホイ合わせられるかというとそういうものでもないので上記Intel EC2はまだまだ現役でいけそうです。

https://aws.amazon.com/jp/blogs/news/announcing-aws-graviton2-support-for-aws-fargate-get-up-to-40-better-price-performance-for-your-serverless-containers/