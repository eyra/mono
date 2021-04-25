#!/bin/bash -e

curl -X POST -H 'Content-type: application/json' \
	--data '{"text":"Shutdown *{{inventory_hostname}}*"}' \
	{{slack_webhook_url}}
