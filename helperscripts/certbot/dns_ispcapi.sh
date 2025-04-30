#!/bin/bash

#
# @file        dns_ispcapi.sh
# @author      Johannes Koschier <hannes@cheat.at>
#


# API token
APIKEY="<<<enter your api key>>>"
APIURL="<<<enter the api URL>>>>"
TASK=$1;
if [ "$TASK" = "auth" ]; then
        DNSURL=`curl -s -X POST "$APIURL/records" \
                -H "Content-Type: application/json" \
                -H "Auth-Token: $APIKEY" \
                -d '{"domain": "_acme-challenge.'$CERTBOT_DOMAIN'", "txt":"'$CERTBOT_VALIDATION'"}'`
        echo $DNSURL
        sleep 70
fi
if [ "$TASK" = "cleanup" ]; then
        DNSURL=`curl -s -X DELETE "$APIURL/records?domain=_acme-challenge.$CERTBOT_DOMAIN" \
                -H "Content-Type: application/json" \
                -H "Auth-Token: $APIKEY"`
        echo $DNSURL
fi
