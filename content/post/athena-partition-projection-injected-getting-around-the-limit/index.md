---
title: Amazon AthenaのPartition ProjectionのInjected型で雑に検索できない制限を回避する
date: 2022-08-30T23:59:51+09:00
tags: [AWS,Athena]
summary: 'Athena最高'
pin: false
draft: false
---

Amazon Athenaでは `IDの動的なパーティション化` が出来ます。  
ref: https://docs.aws.amazon.com/ja_jp/athena/latest/ug/partition-projection-dynamic-id-partitioning.html

その際`Injected`型を使うのですが、そうすると雑に `select * from table` みたいなクエリが打てなくなります。

> Injected projected partition column device_id must have only (and at least one) equality conditions in the WHERE clause! (table default.table)

必ずInjected型に指定した列に対してwhere句を指定する必要があります。    
  
とは言っても雑に見たいときもあるんだよなーということで考えた結果、 **もう一つパーティショニングしてないテーブル作ればいいじゃん！** という結論に辿り着きました。  
もっとスマートな方法を知っている方は [@youyo_](https://twitter.com/youyo_) までご連絡ください。

