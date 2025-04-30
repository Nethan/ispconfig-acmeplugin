#!/bin/bash

#
# Copyright (c) 2025.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of ISPConfig nor the names of its contributors
#       may be used to endorse or promote products derived from this software without
#       specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# @file        dns_ispcapi.sh
# @author      Johannes Koschier <hannes@cheat.at>
#
#

# API token
APIKEY="<<<enter your api key>>>"
APIURL="<<<enter the api URL>>>>"
TASK=$1;
if [ "$TASK" = "auth" ]; then
        DNSURL=`curl -s -X POST $APIURL."/records" \
                -H "Content-Type: application/json" \
                -H "Auth-Token: $APIKEY" \
                -d '{"domain": "_acme-challenge.'$CERTBOT_DOMAIN'", "txt":"'$CERTBOT_VALIDATION'"}'`
        echo $DNSURL
        sleep 20
fi
if [ "$TASK" = "cleanup" ]; then
        DNSURL=`curl -s -X DELETE $APIURL."/records?domain=_acme-challenge.$CERTBOT_DOMAIN" \
                -H "Content-Type: application/json" \
                -H "Auth-Token: $APIKEY"`
        echo $DNSURL
fi
