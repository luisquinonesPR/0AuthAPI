#!/bin/bash
source .env

declare BODY=$(cat<< EOL
{ "client_id":"${AUTH0_CLIENT_ID}",
  "client_secret":"${AUTH0_CLIENT_SECRET}",
  "audience":"${AUTH0_DOMAIN}/api/v2/",
  "grant_type":"client_credentials"}
EOL
)
#cURL get request for accessToken.
curl -o response.json --request POST \
  --url ${AUTH0_DOMAIN}/oauth/token \
  --header 'content-type: application/json'\
  --data "${BODY}"

# Save TOKEN.
TOKEN=$(jq '.access_token' response.json | tr -d '"')

# cURL get request for script JSON data.
curl  -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer  $TOKEN" $AUTH0_DOMAIN/api/v2/rules?fields=script%2Cname -o rules.json

# cURL get request for client JSON data.
curl  -H "Content-Type: application/json" -H "Accept: application/json" -H "Authorization: Bearer  $TOKEN" $AUTH0_DOMAIN/api/v2/clients?fields=name -o client.json

# delete accessToken Json.
rm response.json

# Assign JSON Data into Arrays.
arrRule=()
while IFS= read -r obj; do
    arrRule+=("$obj")
done < <(jq '.[].script' rules.json)

arrRuleName=()
while IFS= read -r obj; do
    arrRuleName+=("$obj")
done < <(jq '.[].name' rules.json)

arrClient=()
while IFS= read -r client; do
    arrClient+=("$client")
done < <(jq -c '.[].name' client.json)

# Trim script array and change single quotes to double quotes.
printf '%s\n' "${arrRule[@]}" | tr -d ' ' > result.txt
cat result.txt | sed -e "s/'/\"/g" > result2.txt

#Find clientName in txt and save to array.
arrMatch=()
while read -r line; do
  for i in "${!arrClient[@]}";do
  if echo $line | grep -q "${arrClient[i]}"; then
    arrMatch+=( $(echo $line | grep -o "${arrClient[i]}"))
  continue
  fi
done
done < result2.txt

#Print output
for i in "${!arrRuleName[@]}";do
 echo "${arrRuleName[i]}"" belongs to " "${arrMatch[i]}" " application."
done
