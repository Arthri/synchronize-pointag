set -eo pipefail

LAST_WORKFLOW_RUN_ID=''

if ! WORKFLOW_RUN_ID="$(gh run list -L 1 --json databaseId -q '.[].databaseId')" ; then
  ec=$?
  echo '::error::Failed to probe workflow runs.'
  exit "$ec"
else
  LAST_WORKFLOW_RUN_ID="$WORKFLOW_RUN_ID"
fi

function expect_no_workflow_run {
  sleep 4
  if ! WORKFLOW_RUN_ID="$(gh run list -L 1 --json databaseId -q '.[].databaseId')" ; then
    ec=$?
    echo '::error::Failed to probe workflow runs.'
    exit "$ec"
  elif [[ $LAST_WORKFLOW_RUN_ID != $WORKFLOW_RUN_ID ]] ; then
    echo '::error::Expected no workflows to trigger.'
    exit 1
  fi
}

function expect_workflow_conclusion {
  sleep 4
  if ! WORKFLOW_RUN_ID="$(gh run list -L 1 --json databaseId -q '.[].databaseId')" ; then
    ec=$?
    echo '::error::Failed to probe workflow runs.'
    exit "$ec"
  elif [[ -z $WORKFLOW_RUN_ID || $WORKFLOW_RUN_ID == $LAST_WORKFLOW_RUN_ID ]] ; then
    echo '::error::Expected a new workflow run, but no new workflow runs triggered.'
    exit 1
  else
    LAST_WORKFLOW_RUN_ID="$WORKFLOW_RUN_ID"
    echo "Waiting for workflow run $WORKFLOW_RUN_ID to finish..."
    gh run watch "$WORKFLOW_RUN_ID" -i 1 > /dev/null
    if ! WORKFLOW_CONCLUSION="$(gh run view "$WORKFLOW_RUN_ID" --json conclusion -q .conclusion)" ; then
      ec=$?
      echo '::error::Failed to retrieve conclusion for the workflow run.'
      exit "$ec"
    elif [[ $WORKFLOW_CONCLUSION != $1 ]] ; then
      echo "::error::Expected the workflow run's conclusion to be \"$1\", but it was instead \"$WORKFLOW_CONCLUSION\"."
      exit 1
    fi
  fi
}

function expect_tag_exists {
  if [[ -z $(git ls-remote --tags origin "refs/tags/$1") ]] ; then
    echo "::error::Expected $1 to exist."
    exit 1
  fi
}

function expect_tag_not_exists {
  if [[ -n $(git ls-remote --tags origin "refs/tags/$1") ]] ; then
    echo "::error::Expected $1 to not exist."
    exit 1
  fi
}

function expect_tags_equal {
  if ! REMOTE_TAGS="$(git ls-remote --tags origin)" ; then
    ec=$?
    echo '::error::Failed to fetch list of tags from origin.'
    exit "$?"
  else
    local tag1_information
    local tag2_information
    if ! tag1_information="$(grep $'\t'"refs/tags/$1$" <<< "$REMOTE_TAGS")" ; then
      echo "::error::Failed to find $1 on remote."
      exit 1
    elif ! tag2_information="$(grep $'\t'"refs/tags/$2$" <<< "$REMOTE_TAGS")" ; then
      echo "::error::Failed to find $2 on remote."
      exit 1
    elif [[ $(cut -s -d ' ' -f 1 <<< "$tag1_information") != $(cut -s -d ' ' -f 1 <<< "$tag2_information") ]] ; then
      echo "::error::Expected $1 and $2 to point at the same revision."
      exit 1
    fi
  fi
}



# Setup
git switch --detach



echo '::group::Expect a skipped workflow run after deleting branches'

git push origin @:refs/heads/feature1
expect_no_workflow_run
sleep 2
git push origin :refs/heads/feature1
expect_workflow_conclusion skipped

echo '::endgroup::'



echo '::group::Expect successful workflow runs with new pointags after pushing new tags.'

git push origin @:refs/tags/v0.0.5
expect_workflow_conclusion success
expect_tags_equal v0 v0.0.5

git push origin @:refs/tags/v1.1.2
expect_workflow_conclusion success
expect_tags_equal v1 v1.1.2

git push origin @:refs/tags/v2.63.12
expect_workflow_conclusion success
expect_tags_equal v2 v2.63.12

git push origin @:refs/tags/v3.94
expect_workflow_conclusion success
expect_tags_equal v3 v3.94

git push origin @:refs/tags/proj.ect/v4.12.5
expect_workflow_conclusion success
expect_tags_equal proj.ect/v4 proj.ect/v4.12.5

git push origin @:refs/tags/proj.ect/v5.96.1
expect_workflow_conclusion success
expect_tags_equal proj.ect/v5 proj.ect/v5.96.1

git push origin @:refs/tags/proj.ect/v6.13.7
expect_workflow_conclusion success
expect_tags_equal proj.ect/v6 proj.ect/v6.13.7

git push origin @:refs/tags/dir/pro.ject/v7.16.1
expect_workflow_conclusion success
expect_tags_equal dir/pro.ject/v7 dir/pro.ject/v7.16.1

git push origin @:refs/tags/dir/pro.ject/v8.6.23
expect_workflow_conclusion success
expect_tags_equal dir/pro.ject/v8 dir/pro.ject/v8.6.23

git push origin @:refs/tags/dir/pro.ject/v9.4.23
expect_workflow_conclusion success
expect_tags_equal dir/pro.ject/v9 dir/pro.ject/v9.4.23

echo '::endgroup::'



echo '::group::Expect successful but no-op workflow runs after pushing non-highest tags.'
git commit --allow-empty --only -m c2

git push origin @:refs/tags/v0.0.4
expect_workflow_conclusion success
expect_tags_equal v0 v0.0.5

git push origin @:refs/tags/v1.0.2
expect_workflow_conclusion success
expect_tags_equal v1 v1.1.2

git push origin @:refs/tags/v2.50.12
expect_workflow_conclusion success
expect_tags_equal v2 v2.63.12

git push origin @:refs/tags/proj.ect/v4.1.2
expect_workflow_conclusion success
expect_tags_equal proj.ect/v4 proj.ect/v4.12.5

git push origin @:refs/tags/proj.ect/v5.23.47
expect_workflow_conclusion success
expect_tags_equal proj.ect/v5 proj.ect/v5.96.1

git push origin @:refs/tags/proj.ect/v6.9.1
expect_workflow_conclusion success
expect_tags_equal proj.ect/v6 proj.ect/v6.13.7

git push origin @:refs/tags/dir/pro.ject/v7.4.7
expect_workflow_conclusion success
expect_tags_equal dir/pro.ject/v7 dir/pro.ject/v7.16.1

git push origin @:refs/tags/dir/pro.ject/v8.4.12
expect_workflow_conclusion success
expect_tags_equal dir/pro.ject/v8 dir/pro.ject/v8.6.23

git push origin @:refs/tags/dir/pro.ject/v9.2.15
expect_workflow_conclusion success
expect_tags_equal dir/pro.ject/v9 dir/pro.ject/v9.4.23

echo '::endgroup::'



echo '::group::Expect a successful but no-op workflow run after deleting a pointag.'

git push origin :refs/tags/v0
expect_workflow_conclusion success
expect_tag_not_exists v0

git push origin :refs/tags/proj.ect/v4
expect_workflow_conclusion success
expect_tag_not_exists proj.ect/v4

git push origin :refs/tags/dir/pro.ject/v7
expect_workflow_conclusion success
expect_tag_not_exists dir/pro.ject/v7

echo '::endgroup::'



echo '::group::Expect a successful but no-op workflow run after deleting tags with no associated pointags.'

git push --atomic origin :refs/tags/v0.0.5 :refs/tags/v0.0.4
expect_workflow_conclusion success
expect_tag_not_exists v0

git push --atomic origin :refs/tags/proj.ect/v4.12.5 :refs/tags/proj.ect/v4.1.2
expect_workflow_conclusion success
expect_tag_not_exists proj.ect/v4

git push --atomic origin :refs/tags/dir/pro.ject/v7.16.1 :refs/tags/dir/pro.ject/v7.4.7
expect_workflow_conclusion success
expect_tag_not_exists dir/pro.ject/v7

echo '::endgroup::'



echo '::group::Expect a successful but no-op workflow run after deleting a non-highest tag.'

git push origin :refs/tags/v1.0.2
expect_workflow_conclusion success
expect_tags_equal v1 v1.1.2

git push origin :refs/tags/proj.ect/v5.23.47
expect_workflow_conclusion success
expect_tags_equal proj.ect/v5 proj.ect/v5.96.1

git push origin :refs/tags/dir/pro.ject/v8.4.12
expect_workflow_conclusion success
expect_tags_equal dir/pro.ject/v8 dir/pro.ject/v8.6.23

echo '::endgroup::'



echo '::group::Expect a successful workflow run which updates the pointag to the next highest tag after deleting the highest tag.'

git push origin :refs/tags/v2.63.12
expect_workflow_conclusion success
expect_tags_equal v2 v2.50.12

git push origin :refs/tags/proj.ect/v6.13.7
expect_workflow_conclusion success
expect_tags_equal proj.ect/v6 proj.ect/v6.9.1

git push origin :refs/tags/dir/pro.ject/v9.4.23
expect_workflow_conclusion success
expect_tags_equal dir/pro.ject/v9 dir/pro.ject/v9.2.15

echo '::endgroup::'



echo '::group::Expect a successful workflow run which deletes the pointag after deleting every tag under the associated major version.'

git push origin :refs/tags/v1.1.2
expect_workflow_conclusion success
expect_tag_not_exists v1

git push origin :refs/tags/proj.ect/v5.96.1
expect_workflow_conclusion success
expect_tag_not_exists proj.ect/v5

git push origin :refs/tags/dir/pro.ject/v8.6.23
expect_workflow_conclusion success
expect_tag_not_exists dir/pro.ject/v8

echo '::endgroup::'
