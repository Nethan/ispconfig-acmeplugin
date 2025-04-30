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

# shellcheck disable=SC2034
dns_ispcapi_info='ISPCONFIG Plugin acmeapi
Author: Johannes Koschier <hannes@cheat.at>
'

########  Public functions #####################

export ACME_DNS_TIMEOUT=4

dns_ispcapi_add() {
  fulldomain=$1
  txtvalue=$2

  #Workaround to allow multiple accounts with same plugin
  #https://github.com/acmesh-official/acme.sh/issues/1278
  fqdnmd5sum="$(echo -n "$fulldomain" | md5sum | awk -F " " '{print $1}')"
  ISPCAPI_KEY_NAME="ISPCAPI_KEY$fqdnmd5sum"
  ISPCAPI_URL_NAME="ISPCAPI_URL$fqdnmd5sum"



  ISPCAPI_KEY="${ISPCAPI_KEY:-$(_readaccountconf_mutable ISPCAPI_KEY_NAME)}"
  ISPCAPI_URL="${ISPCAPI_URL:-$(_readaccountconf_mutable ISPCAPI_URL_NAME)}"
  if [ -z "$ISPCAPI_KEY" ] || [ -z "$ISPCAPI_URL" ]; then
    ISPCAPI_KEY=""
    ISPCAPI_URL=""
    _err "You don't specify api key and url."
    return 1
  fi

  _saveaccountconf_mutable $ISPCAPI_URL_NAME "$ISPCAPI_URL"
  _saveaccountconf_mutable $ISPCAPI_KEY_NAME "$ISPCAPI_KEY"

        _debug XXXXXXXXXXXXXXXXXXXX
        _debug $ISPCAPI_URL
        _debug $ISPCAPI_URL_NAME
  _debug "Adding record: $fulldomain = $txtvalue"

  # Prepare JSON payload
  body="{\"domain\":\"$fulldomain\", \"txt\":\"$txtvalue\"}"

  #export _H1="Authorization: Bearer $ISPCAPI_KEY"
  export _H1="Auth-Token: $ISPCAPI_KEY"
  response="$(_post "$body" "$ISPCAPI_URL/records" "" "POST")"

  _debug "Response: $response"

  if _contains "$response" '"message":"SUCCESS - TXT record added"'; then
    _info "Successfully added TXT record"
    return 0
  elif _startswith "$response" "{"; then
    _err "Error adding TXT record, but the response format was valid JSON. Response: $response"
    return 1
  else
    _err "Unexpected response: $response"
    return 1
  fi

  _err "Error adding TXT record"
  return 1
}

dns_ispcapi_rm() {
  fulldomain=$1
  txtvalue=$2
  _info "Using ispcapi"

  _debug "Removing record: $fulldomain = $txtvalue"

  #Workaround to allow multiple accounts with same plugin
  #https://github.com/acmesh-official/acme.sh/issues/1278
  fqdnmd5sum="$(echo -n "$fulldomain" | md5sum | awk -F " " '{print $1}')"
  ISPCAPI_KEY_NAME="ISPCAPI_KEY$fqdnmd5sum"
  ISPCAPI_URL_NAME="ISPCAPI_URL$fqdnmd5sum"

  ISPCAPI_KEY="${ISPCAPI_KEY:-$(_readaccountconf_mutable ISPCAPI_KEY_NAME)}"
  ISPCAPI_URL="${ISPCAPI_URL:-$(_readaccountconf_mutable ISPCAPI_URL_NAME)}"
  if [ -z "$ISPCAPI_KEY" ] || [ -z "$ISPCAPI_URL" ]; then
    ISPCAPI_KEY=""
    ISPCAPI_URL=""
    _err "You don't specify api key and url."
    return 1
  fi

  export _H1="Auth-Token: $ISPCAPI_KEY"
  response="$(_post "" "$ISPCAPI_URL/records?domain=$fulldomain" "" "DELETE")"

  _debug "Response: $response"

  if _contains "$response" '"message":"SUCCESS - TXT record removed"'; then
    _info "Successfully removed TXT record"
    return 0
  elif _startswith "$response" "{"; then
    _err "Error remove TXT record, but the response format was valid JSON. Response: $response"
    return 1
  else
    _err "Unexpected response: $response"
    return 1
  fi

  _err "Error removing TXT record"
  return 1

}