#!/bin/bash

BASE_DIR='./content/post'
TITLE="${1}"
TITLE_JP="${2}"
DATE=`date +'%Y-%m-%dT%T+09:00'`

mkdir ${BASE_DIR}/${TITLE}
cat <<EOF> ${BASE_DIR}/${TITLE}/index.md
---
title: ${TITLE_JP}
date: ${DATE}
tags: []
summary: ''
pin: false
draft: false
---

EOF
