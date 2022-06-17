---
title: aws-cdk-goを使ってコンテナイメージのlambdaをデプロイする
date: 2022-06-17T11:00:00+09:00
tags: [AWS,Lambda,Docker,container,CDK,Go]
summary: CDK最高
pin: false
draft: false
---

## 環境

```
$ uname -m
arm64
```
```
$ node --version
v16.15.1
```
```
$ npx cdk --version
2.27.0 (build 8e89048)
```
```
$ go version
go version go1.18.3 darwin/arm64
```

## Deploying by cdk-go

```
$ mkdir cdk-go
$ cd cdk-go
$ npx cdk init --language go
```
```
$ tree
.
├── README.md
├── cdk-go.go
├── cdk-go_test.go
├── cdk.json
└── go.mod

0 directories, 5 files
```
```
$ go mod edit -go=1.18
```

```
// 出力内容がちょっとでも見やすくなるように追記
$ vim cdk.json
{
  "versionReporting": false,
}
```
```
$ npx cdk bootstrap
```
```go
// cdk-go.go

package main

import (
	"github.com/aws/aws-cdk-go/awscdk/v2"
	"github.com/aws/aws-cdk-go/awscdk/v2/awslambda"
	"github.com/aws/aws-cdk-go/awscdk/v2/awslogs"
	"github.com/aws/constructs-go/constructs/v10"
	"github.com/aws/jsii-runtime-go"
)

type CdkGoStackProps struct {
	awscdk.StackProps
}

func NewCdkGoStack(scope constructs.Construct, id string, props *CdkGoStackProps) awscdk.Stack {
	var sprops awscdk.StackProps
	if props != nil {
		sprops = props.StackProps
	}
	stack := awscdk.NewStack(scope, &id, &sprops)

	// Lambda関数
	f := awslambda.NewDockerImageFunction(stack, jsii.String("Lambda"), &awslambda.DockerImageFunctionProps{
		Code:         awslambda.DockerImageCode_FromImageAsset(jsii.String("lambda/"), nil),
		Architecture: awslambda.Architecture_ARM_64(),
		LogRetention: awslogs.RetentionDays_SIX_MONTHS,

		Environment: &map[string]*string{
			"STAGE": jsii.String("develop"),
		},
	})
	// テストしやすいようにFunctional URL作成しておく
	fUrl := f.AddFunctionUrl(&awslambda.FunctionUrlOptions{
		AuthType: awslambda.FunctionUrlAuthType_AWS_IAM,
	})
	awscdk.NewCfnOutput(stack, jsii.String("FunctionalURL"), &awscdk.CfnOutputProps{
		Value: fUrl.Url(),
	})

	return stack
}

func main() {
	app := awscdk.NewApp(nil)

	NewCdkGoStack(app, "CdkGoStack", &CdkGoStackProps{
		awscdk.StackProps{
			Env: env(),
		},
	})

	app.Synth(nil)
}

func env() *awscdk.Environment {
	return nil
}
```
```
$ mkdir lambda
$ touch lambda/requirements.txt
```
```python
# lambda/app.py

import json


def handler(event, context):
    return {
        'statusCode': 200,
        'body': json.dumps({'success': True})
    }
```
```shell
# lambda/Dockerfile

FROM public.ecr.aws/lambda/python:3.9
COPY app.py ${LAMBDA_TASK_ROOT}
COPY requirements.txt  .
RUN  pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"
CMD [ "app.handler" ]
```

```shell
$ go mod tidy
$ npx cdk diff
$ npx cdk deploy
```
```shell
# ref: https://note.youyo.io/post/sample-request-to-aws-api-with-curl-aws-sigv4-option/

$ curl -s https://********.lambda-url.ap-northeast-1.on.aws/ \
-H "X-Amz-Security-Token: ${AWS_SESSION_TOKEN}" \
> --aws-sigv4 "aws:amz:ap-northeast-1:lambda" \
> --user "${AWS_ACCESS_KEY_ID}:${AWS_SECRET_ACCESS_KEY}"
{"success": true}
```

## 補足

- Dockerfile内でベースイメージとして`public.ecr.aws/lambda/python:3.9`を利用しているが、`public.ecr.aws/lambda/python:3.9-x86_64`と`public.ecr.aws/lambda/python:3.9-arm64`を使い分けることで好きなアーキテクチャーで実行できる。  
https://gallery.ecr.aws/lambda/python