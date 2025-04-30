#!/bin/bash

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