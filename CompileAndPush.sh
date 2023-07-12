#!/bin/bash

commitmessage=$1

print $commitmessage

cd Biblio

perl UpDateBiblio.pl 

cd ..

git add *

git commit -m $commitmessage
git push
