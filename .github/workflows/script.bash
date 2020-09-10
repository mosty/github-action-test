#!/bin/bash
set -euxo pipefail

env

sudo apt-get install jq curl

remove_label() {
	local url=$(echo $GITHUB_CONTEXT | jq --raw-output .event.pull_request._links.issue.href)/labels/merge-me

	curl -X DELETE -H "Accept: application/vnd.github.v3+json" \
		--header "authorization: Bearer $GITHUB_TOKEN" "$url"
}

add_comment() {
	local comment="$1"
	local url=$(echo $GITHUB_CONTEXT | jq --raw-output .event.pull_request._links.comments.href)
	local data=$(jq --null-input --arg body "$comment" '{ body: $body }')

	curl --request POST --url "$url" \
		--header "authorization: Bearer $GITHUB_TOKEN" \
		--header 'content-type: application/json' \
		--data "$data"
}

close_issue() {
	local url=$(echo $GITHUB_CONTEXT | jq --raw-output .event.pull_request._links.issue.href)

	curl -X PATCH -H "Accept: application/vnd.github.v3+json" \
		--header "authorization: Bearer $GITHUB_TOKEN" $url \
		-d '{"state": "closed"}'
}

check_state() {
	local merged="$(echo $GITHUB_CONTEXT | jq --raw-output .event.pull_request.merged)"
	if [ "$merged" != false ]
	then
		add_comment "PR is already merged"
		remove_label
		exit 1
	fi

	local mergeable="$(echo $GITHUB_CONTEXT | jq --raw-output .event.pull_request.mergeable)"
	if [ "$mergeable" != true ]
	then
		add_comment "PR does not seem to be mergeable"
		remove_label
		exit 1
	fi
}

check_state

add_comment "testing leaving a comment"
remove_label
close_issue
