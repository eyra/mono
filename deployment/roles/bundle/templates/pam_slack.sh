#!/bin/bash -e

if [ "$PAM_TYPE" == "open_session" ]; then
	curl -X POST -H 'Content-type: application/json' \
		--data '{"text":"SSH Login: *'"$PAM_USER"'* logged into *{{inventory_hostname}}* from *'"$PAM_RHOST"'*"}' \
		{{slack_webhook_url}}
fi
