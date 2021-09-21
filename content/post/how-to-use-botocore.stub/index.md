---
title: botocore.stubを使ったテストコードメモ
date: 2021-09-21T12:30:00+09:00
tags: [AWS, Python, boto3, Test]
summary: botocore.stubを使ったテストコードメモ
pin: false
draft: false
---

boto3 を使ったコードをテストする場合、基本的には[moto](https://github.com/spulec/moto)を使うことが多いのですが moto が対応していない API などのテストが必要になった際には botocore.stub を使うことがあります。
そのときのメモ。

- IoTCore の名前付き Shadow の `get_thing_shadow`

```python
import json
import boto3
import unittest
from botocore.stub import Stubber
from unittest import mock
from io import BytesIO
from botocore.response import StreamingBody


def handler():
    iot_data_client = boto3.client('iot-data')
    response = iot_data_client.get_thing_shadow(
        thingName='thing_name',
        shadowName='shadow_name',
    )
    return json.loads(response['payload'].read().decode('utf-8'))


class TestHandler(unittest.TestCase):
    def test_handler_stubber_success(self):
        iot_data_client = boto3.client('iot-data')
        stubber_iot_data = Stubber(iot_data_client)
        payload_encoded = json.dumps({'key': 'value'}).encode()
        stubber_iot_data.add_response(
            'get_thing_shadow', {'payload': StreamingBody(BytesIO(payload_encoded), len(payload_encoded))})

        stubber_iot_data.activate()

        with mock.patch('boto3.client', return_value=iot_data_client):
            expected = {'key': 'value'}
            actual = handler()
            self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
```

- Resource API(高レベル API)で S3 のオブジェクト一覧を取得する

```python
import boto3
import unittest
from botocore.stub import Stubber
from unittest import mock
from collections import deque


# 末尾のオブジェクトを一つ取得する
def handler():
    s3_resource = boto3.resource('s3')
    objects_iter = s3_resource.Bucket('s3_bucket_name').objects.filter(
        Prefix='test/',
    )
    key = deque(objects_iter, maxlen=1).pop().key
    return key


class TestHandler(unittest.TestCase):
    def test_handler_stubber_success(self):
        s3_resource = boto3.resource('s3')
        stubber_s3_resource = Stubber(s3_resource.meta.client)
        stubber_s3_resource.add_response(
            'list_objects', {
                'Contents': [
                    {'Key': 'test/test1.json'},
                    {'Key': 'test/test2.json'},
                ],
            },
        )
        stubber_s3_resource.activate()

        with mock.patch('boto3.resource', return_value=s3_resource):

            expected = 'test/test2.json'
            actual = handler()
            self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
```

- Resource API(高レベル API)で S3 のオブジェクト一覧を取得してそのオブジェクトの中身も取得する

```python
import json
import boto3
import unittest
from botocore.stub import Stubber
from unittest import mock
from io import BytesIO
from botocore.response import StreamingBody
from collections import deque


def handler():
    s3_resource = boto3.resource('s3')
    objects_iter = s3_resource.Bucket('s3_bucket_name').objects.filter(
        Prefix='test/',
    )
    key = deque(objects_iter, maxlen=1).pop().key
    body = s3_resource.Object('s3_bucket_name', key).get()['Body'].read()
    return json.loads(body)


class TestHandler(unittest.TestCase):
    def test_handler_stubber_success(self):
        s3_resource = boto3.resource('s3')

        stubber_s3_resource = Stubber(s3_resource.meta.client)
        stubber_s3_resource.add_response(
            'list_objects', {
                'Contents': [
                    {'Key': 'test/test1.json'},
                    {'Key': 'test/test2.json'},
                ],
            },
        )

        payload_encoded = json.dumps({'key': 'value'}).encode()
        stubber_s3_resource.add_response(
            'get_object', {'Body': StreamingBody(BytesIO(payload_encoded), len(payload_encoded))})

        stubber_s3_resource.activate()

        with mock.patch('boto3.resource', return_value=s3_resource):
            expected = {'key': 'value'}
            actual = handler()
            self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
```

- 複数のリソース(iot-data, s3)を組み合わせて stub

```python
import json
import boto3
import unittest
from botocore.stub import Stubber
from unittest import mock
from io import BytesIO
from botocore.response import StreamingBody
from collections import deque


def handler():
    iot_data_client = boto3.client('iot-data')
    response = iot_data_client.get_thing_shadow(
        thingName='thing_name',
        shadowName='shadow_name',
    )
    things = json.loads(response['payload'].read().decode('utf-8'))
    s3_bucket_name = things['bucket_name']

    s3_resource = boto3.resource('s3')
    objects_iter = s3_resource.Bucket(s3_bucket_name).objects.filter(
        Prefix='test/',
    )
    key = deque(objects_iter, maxlen=1).pop().key
    body = s3_resource.Object(s3_bucket_name, key).get()['Body'].read()
    return json.loads(body)


class TestHandler(unittest.TestCase):
    def test_handler_stubber_success(self):
        iot_data_client = boto3.client('iot-data')
        stubber_iot_data = Stubber(iot_data_client)
        payload_encoded = json.dumps({'bucket_name': 's3_bucket_name'}).encode()
        stubber_iot_data.add_response(
            'get_thing_shadow', {'payload': StreamingBody(BytesIO(payload_encoded), len(payload_encoded))})

        s3_resource = boto3.resource('s3')
        stubber_s3_resource = Stubber(s3_resource.meta.client)
        stubber_s3_resource.add_response(
            'list_objects', {
                'Contents': [
                    {'Key': 'test/test1.json'},
                    {'Key': 'test/test2.json'},
                ],
            },
        )

        payload_encoded = json.dumps({'key': 'value'}).encode()
        stubber_s3_resource.add_response(
            'get_object', {'Body': StreamingBody(BytesIO(payload_encoded), len(payload_encoded))})

        stubber_iot_data.activate()
        stubber_s3_resource.activate()

        with mock.patch('boto3.client', return_value=iot_data_client):
            with mock.patch('boto3.resource', return_value=s3_resource):
                expected = {'key': 'value'}
                actual = handler()
                self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
```
