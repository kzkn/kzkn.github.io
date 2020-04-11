#!/bin/sh

mkdir -p out
curl -L https://github.com/gohugoio/hugo/releases/download/v0.54.0/hugo_0.54.0_Linux-64bit.tar.gz >out/hugo.tgz
cd out && tar xvf hugo.tgz
