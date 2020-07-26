#!/bin/bash

# Configure these variables
hassApi="http://localhost:8123/api"
hassApiToken=""
getTokenScriptPath="/path/to/get_tokens.py"
grpCurlPath="/path/to/grpcurl"
protoPath="/path/to/protofiles"
targetDevices=("Device One" "Device Two")
healthCheck=true
healthCheckUrl=https://hc-ping.com/your-hc-token
# End config

# Grab Google access token
echo "Grabbing access token..."
accessToken=$(/usr/bin/python3 $getTokenScriptPath | grep 'Access token:' | cut -d' ' -f4)

# Grab and parse the list of per-device local auth tokens
echo "Grabbing list of local authentication tokens..."
localAuthTokenList=$($grpCurlPath -H "authorization: Bearer $accessToken" -import-path $protoPath -proto $protoPath/google/internal/home/foyer/v1.proto googlehomefoyer-pa.googleapis.com:443 google.internal.home.foyer.v1.StructuresService/GetHomeGraph | jq '.home.devices[] | {deviceName, localAuthToken}')

# Prepare list of tokens from result
stamp=$(/bin/date)
entities="\"last_set\": \"$stamp\""

for device in "${targetDevices[@]}"; do
    localAuthToken=$(echo $localAuthTokenList | jq -r --arg device "$device" '. | select (.deviceName==$device).localAuthToken')
    echo "Got authentication token for $device."
    entities=$(echo $entities ", \"token_$device\": \"$localAuthToken\"")
done

jsonObj="{\"state\": \"Tokening\", \"attributes\": {$entities}}"

# Push relevant tokens to hass API
/usr/bin/curl -s -X POST -H "Authorization: Bearer $hassApiToken" \
  -H "Content-Type: application/json" \
  -d "$jsonObj" \
  "$hassApi/states/input_text.google_tokens" > /dev/null

if [ $? -eq 0 ]; then
    echo "Home assistant keys updated."

    if [ "$healthCheck" = true ] ; then
    /usr/bin/curl -s -m 10 --retry 5 "$healthCheckUrl" > /dev/null
    fi
else
    echo "Something went wrong, check script config."
fi
