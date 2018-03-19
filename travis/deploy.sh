#!/bin/sh

cd public

git config user.email "kz.nishikawa@gmail.com"
git config user.name "Kazuki Nishikawa"

git add .
git commit -m 'deploy to github pages'
git push origin master
