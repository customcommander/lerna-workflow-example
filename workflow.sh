#!/bin/sh

make_change () {
  cat /workspaces/run/burrito.txt >>packages/$1/README.md
  git commit -q -a -m "making some change in package $1"
}

package_info() {
  jq -cr '{name, version}' packages/**/package.json
  jq '.dependencies' packages/website/package.json
}

current_branch() {
  echo "branch: $(git rev-parse --abbrev-ref HEAD)"
}

cd /workspaces/dev

echo "
==== START ==============================
"

# -----------------------------------------------------------------------------

echo "
$(current_branch)
first development cycle ever: 1.0.0-alpha.0
we never published anything with lerna yet.
let's publish what we have so far.
publishing...
"

npx lerna publish --yes prerelease 2>/dev/null
package_info

# -----------------------------------------------------------------------------

echo "
$(current_branch)
made three commits to 'lib_a'.
publishing...
"

make_change lib_a
make_change lib_a
make_change lib_a
npx lerna publish --yes prerelease 2>/dev/null
package_info

# -----------------------------------------------------------------------------

git checkout -b release/v1.0.0
git push origin release/v1.0.0

echo "
$(current_branch)
ready to make our first beta release: 1.0.0-beta.0
publishing...
"

npx lerna publish --yes --force-publish=* --preid=beta prerelease 2>/dev/null
package_info

# -----------------------------------------------------------------------------

git checkout -b master integration
git merge release/v1.0.0
git push origin master

echo "
$(current_branch)
we're ready to make our first production release: 1.0.0
publishing...
"

npx lerna publish --yes --force-publish=* minor 2>/dev/null
package_info

# -----------------------------------------------------------------------------

git checkout integration

echo "
$(current_branch)
start of second development cycle: 1.1.0-alpha.0
updating packages to reflect new development cycle.
publishing...
"

npx lerna publish --yes --force-publish=* --preid=alpha preminor 2>/dev/null
package_info

# -----------------------------------------------------------------------------

echo "
$(current_branch)
made some work on lib_a
made some work on lib_b
publishing...
"

make_change lib_a
make_change lib_b
npx lerna publish --yes prerelease 2>/dev/null
package_info

# -----------------------------------------------------------------------------

make_change lib_c
git checkout release/v1.0.0
git cherry-pick integration --strategy-option=theirs

echo "
$(current_branch)
found major issue in 1.0.0 in lib_c
made the fix on integration and cherry-picked the change on the release/v1.0.0 branch
publishing...
"

npx lerna publish --yes --force-publish=* --preid=beta prepatch 2>/dev/null
package_info

# -----------------------------------------------------------------------------

git checkout master
git merge release/v1.0.0 --strategy-option=theirs --no-edit

echo "
$(current_branch)
merged hotfix in release/v1.0.0 into master
publishing...
"

npx lerna publish --yes --force-publish=* patch 2>/dev/null
package_info

# -----------------------------------------------------------------------------

git checkout -b release/v1.1.0 integration
git push origin release/v1.1.0

echo "
$(current_branch)
ready to make our second beta release: 1.1.0-beta.0
publishing...
"

npx lerna publish --yes --force-publish=* --preid=beta prerelease 2>/dev/null
package_info

# -----------------------------------------------------------------------------

git checkout master
git merge release/v1.1.0 --strategy-option=theirs --no-edit
git push origin master

echo "
$(current_branch)
we're ready to make our second production release: 1.1.0
publishing...
"

npx lerna publish --yes --force-publish=* minor 2>/dev/null
package_info

# -----------------------------------------------------------------------------

make_change lib_c
git checkout release/v1.1.0
git cherry-pick integration --strategy-option=theirs

echo "
$(current_branch)
found major issue in 1.1.0 in lib_c
made the fix on integration and cherry-picked the change on the release/v1.1.0 branch
publishing...
"

npx lerna publish --yes --force-publish=* --preid=beta prepatch 2>/dev/null
package_info

# -----------------------------------------------------------------------------

git checkout master
git merge release/v1.1.0 --strategy-option=theirs --no-edit

echo "
$(current_branch)
merged hotfix in release/v1.1.0 into master
publishing...
"

npx lerna publish --yes --force-publish=* patch 2>/dev/null
package_info