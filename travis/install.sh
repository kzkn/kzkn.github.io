#!/bin/sh

mkdir -p out
curl -L https://github.com/gohugoio/hugo/releases/download/v0.40.3/hugo_0.40.3_Linux-64bit.tar.gz >out/hugo.tgz
cd out && tar xvf hugo.tgz
