---
title: "Travis CI to GitHub Actions (Hugo)"
date: 2020-04-26T14:34:04+09:00
draft: false
---

Travis CI でやっていた [Hugo で作ってるサイト](https://kazkn.com/)のビルドとデプロイを、GitHub Actions に移行した。前からぼんやり「移行しなきゃな〜」とは思っていたのだけど、最近 Travis CI を使おうと思ったときにメンテナンスの時間帯にあたってしまうというのが続いてしまったのもあって、一念発起して移行した。

GitHub Actions の設定はこんな感じ。雑に準備、ビルド、デプロイ（git push）まで 1 つのジョブにまとめてる。

```yaml
name: deploy

on:
  push:
    branches: [ hugo ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
      with:
        ref: hugo

    - uses: actions/checkout@v2
      with:
        ref: master
        path: public

    - name: Install hugo
      uses: peaceiris/actions-hugo@v2
      with:
        hugo-version: '0.69.2'

    - name: Build
      run: hugo

    - name: Commit
      run: |
        git config --local user.email "kz.nishikawa@gmail.com"
        git config --local user.name "Kazuki Nishikawa"
        git commit -am "actions build"
      working-directory: public

    - name: Push
      uses: ad-m/github-push-action@master
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        directory: public
```

Hugo のコードは hugo ブランチ入れてるので、ビルド対象は hugo ブランチだけにした。
ビルド結果（＝公開サイトのコンテンツ）は master ブランチに入れているので、ビルドの出力ディレクトリに master ブランチを clone しておく。

あとは hugo をインストールして、hugo 叩いて、master ブランチにコミット & push する。

hugo のインストールは [peaceiris/actions-hugo](https://github.com/peaceiris/actions-hugo) を使った。自前で curl を使ってインストールするでもよかったんだけど、今回はありものを使ってみた。

git push には [ad-m/github-push-action](https://github.com/ad-m/github-push-action) を使った。`secrets.GITHUB_TOKEN` は[自動的に設定されるもの](https://help.github.com/ja/actions/configuring-and-managing-workflows/authenticating-with-the-github_token)らしく、これといってリポジトリに追加の設定をする必要はなかった。

このサイトは github.io で運用してるので、push すれば終わり。

ちょろっと使った感じ、Travis CI より速く動いてると思う。

ちなみに Travis CI の設定はこんな感じだった。

```yaml
### .travis.yml

language: minimal
before_install: travis/fetch.sh
install: travis/install.sh
script: travis/build.sh
after_success: travis/deploy.sh
env:
  global:
    secure: blahblahblah
```

```sh
### travis/fetch.sh
#!/bin/sh
git clone https://${GH_TOKEN}@github.com/kzkn/kzkn.github.io public


### travis/install.sh
#!/bin/sh
mkdir -p out
curl -L https://github.com/gohugoio/hugo/releases/download/v0.69.0/hugo_0.69.0_Linux-64bit.tar.gz >out/hugo.tgz
cd out && tar xvf hugo.tgz


### travis/build.sh
#!/bin/sh
./out/hugo
echo $PWD
ls


### travis/deploy.sh
#!/bin/sh
cd public

git config user.email "kz.nishikawa@gmail.com"
git config user.name "Kazuki Nishikawa"

git add .
git commit -m "Travis build: $TRAVIS_BUILD_NUMBER"
git push origin master
```
