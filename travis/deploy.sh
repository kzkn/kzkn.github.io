#!/bin/sh

cd public

git config user.email "kz.nishikawa@gmail.com"
git config user.name "Kazuki Nishikawa"

git add .
git commit -m "Travis build: $TRAVIS_BUILD_NUMBER"
git push origin master
