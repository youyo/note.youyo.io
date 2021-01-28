---
title: Hugo GitHub-StyleでGoogle Analyticsを有効にする
date: 2021-01-29T00:09:05+09:00
tags: [Hugo,Google-Analytics]
summary: '環境変数: HUGO_ENV=production を設定することで解決'
pin: false
draft: false
---

公式ドキュメントには `googleAnalytics = "UA-123456-789"` というconfigがあり, これを記述すれば有効になると思ったけど実際にはならなかった。  
https://themes.gohugo.io/github-style/#configtoml-example

```bash
$ echo 'googleAnalytics = "UA-123456-789"' >> config.toml
$ hugo server
```

`themes/github-style/layouts/partials/extended_head.html` を見ると `HUGO_ENV` で条件分岐していることがわかった。

```html
<!-- Google Analytics -->
{{ if eq (getenv "HUGO_ENV") "production"}}
{{ with .Site.GoogleAnalytics }}
<script async src="https://www.googletagmanager.com/gtag/js?id={{ . }}"></script>
<script>
  if (navigator.doNotTrack !== '1') {
    window.dataLayer = window.dataLayer || [];
    function gtag() { dataLayer.push(arguments); }
    gtag('js', new Date());

    gtag('config', '{{ . }}');
  }
</script>
{{ end }}
{{ end }}
```

`HUGO_ENV=production` を設定することで解決:slightly_smiling_face:

```bash
$ HUGO_ENV=production hugo server
```

ちなみにちゃんとドキュメントにも記載ありました:innocent:

>Here is an sample. Note line 22 have env HUGO_ENV="production", makes sure googleAnalysis is loaded during production, but is not loaded when we are testing it in localhost.

https://themes.gohugo.io/github-style/#deploysh-example
