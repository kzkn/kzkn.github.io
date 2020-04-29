---
title: "Travis CI to GitHub Actions (Ruby on Rails)"
date: 2020-04-26T14:54:01+09:00
draft: false
---

Travis CI でやっていた Rails 製サイトの RSpec 実行を、GitHub Actions に移行した。前からぼんやり「移行しなきゃな〜」とは思っていたのだけど、最近 Travis CI を使おうと思ったときにメンテナンスの時間帯にあたってしまうというのが続いてしまったのもあって、一念発起して移行した。

GitHub Actions の設定はこんな感じ。

```yaml
name: test

on: [push]

jobs:
  build:

    runs-on: ubuntu-latest

    env:
      RAILS_ENV: test
      TZ: Asia/Tokyo

    services:
      postgres:
        image: postgres:12
        ports:
          - 5432:5432
        env:
          POSTGRES_USER: pguser
          POSTGRES_PASSWORD: password

    steps:
    - uses: actions/checkout@v2

    - name: Set up Ruby 2.7
      uses: actions/setup-ruby@v1
      with:
        ruby-version: 2.7

    - name: Get yarn cache directory path
      id: yarn-cache-dir-path
      run: echo "::set-output name=dir::$(yarn cache dir)"

    - uses: actions/cache@v1
      id: yarn-cache # use this to check for `cache-hit` (`steps.yarn-cache.outputs.cache-hit != 'true'`)
      with:
        path: ${{ steps.yarn-cache-dir-path.outputs.dir }}
        key: ${{ runner.os }}-yarn-${{ hashFiles('**/yarn.lock') }}
        restore-keys: |
          ${{ runner.os }}-yarn-

    - uses: actions/cache@v1
      with:
        path: vendor/bundle
        key: ${{ runner.os }}-gems-${{ hashFiles('**/Gemfile.lock') }}
        restore-keys: |
          ${{ runner.os }}-gems-

    - name: Install dependencies
      run: |
        gem install bundler
        bundle config path vendor/bundle
        bundle install --jobs 4 --retry 3
        yarn

    - name: Setup database
      run: |
        cp config/database.yml.actions config/database.yml
        bundle exec rails db:create db:migrate

    - name: Run test
      run: |
        COVERAGE=1 bundle exec rspec

    - name: Upload coverage report
      if: always()
      uses: actions/upload-artifact@v2
      with:
        name: coverage
        path: coverage

    - name: Upload screenshots
      if: failure()
      uses: actions/upload-artifact@v2
      with:
        name: screenshots
        path: tmp/screenshots
```

PostgreSQL は[サービスコンテナ](https://help.github.com/ja/actions/configuring-and-managing-workflows/about-service-containers)として起動してる。ここに繋ぐための設定を config/database.yml.actions としてあらかじめ定義しておき、データベースのセットアップ前に config/database.yml に上書きしている。config/database.yml.actions はこんな感じ。

```yaml
test:
  adapter: postgresql
  database: actions_test
  host: localhost
  user: pguser
  password: password
```

yarn と bundle をキャッシュするようにしてる。この辺の設定は [actions/cache](https://github.com/actions/cache) にあった設定例を丸っと拝借している。

Headless Chrome を使った System Spec もあるプロジェクトなんだけど、[Chrome は実行環境にあらかじめインストールされている](https://github.com/actions/virtual-environments/blob/master/images/linux/Ubuntu1804-README.md)ので、Chrome をインストールするためのコードは不要。

テスト実行による副産物を Artifact として保存するようにしている。simplecov が出力するカバレッジレポートと、System Spec (Headless Chrome) が失敗したときに自動取得されるスクリーンショット。Zip にアーカイブされて、ダウンロードできるようになる。カバレッジレポートはテストが失敗しても取得するように、スクショはテストが失敗したときだけ取得するようにしている。

キャッシュもちゃんと効いてるし、実行スピードも特に不満はなく、今のところは目立ったデメリットを感じてない。

ちなみに Travis CI の設定はこんな感じだった。キャッシュの設定は腐ってると思う。ビルドの動きを見てた感じ、たぶん効いてなかった。

```yaml
language: ruby

services:
  - postgresql

cache:
  bundler: true
  directories:
    - node_modules
  yarn: true

before_install:
  - sudo apt-get update
  - sudo apt-get install -y libappindicator3-1
  - curl -L -o google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  - sudo dpkg -i google-chrome.deb

install:
  - bundle install --jobs=3 --retry=3
  - nvm install 10
  - node -v
  - npm i -g yarn
  - yarn

before_script:
  - export TZ=Asia/Tokyo
  - cp config/database.yml.travisci config/database.yml
  - RAILS_ENV=test bundle exec rails db:create db:migrate

script:
  - bundle exec rspec

notifications:
  email: false
```
