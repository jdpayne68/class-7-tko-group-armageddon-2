#!/usr/bin/env bash
set -euo pipefail

# Run this from the root of your local class group repository.
mkdir -p members/marvin-evins
cp -R marvin_evins_deliverables members/marvin-evins/deliverables

git add members/marvin-evins/deliverables
git status

echo "Review the files above, then commit with:"
echo 'git commit -m "Add Marvin Evins Phase 1 and Phase 2 deliverables"'
echo 'git push classrepo main:member/marvin-evins'
