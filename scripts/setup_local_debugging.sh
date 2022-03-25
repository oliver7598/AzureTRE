#!/bin/bash
set -e

: ${TRE_ID?"You have not set you TRE_ID in ./templates/core/.env"}
: ${RESOURCE_GROUP_NAME?"Check RESOURCE_GROUP_NAME is defined in ./templates/core/private.env"}
: ${SERVICE_BUS_RESOURCE_ID?"Check SERVICE_BUS_RESOURCE_ID is defined in ./templates/core/private.env"}
: ${STATE_STORE_RESOURCE_ID?"Check STATE_STORE_RESOURCE_ID is defined in ./templates/core/private.env"}
: ${COSMOSDB_ACCOUNT_NAME?"Check COSMOSDB_ACCOUNT_NAME is defined in ./templates/core/private.env"}
: ${AZURE_SUBSCRIPTION_ID?"Check AZURE_SUBSCRIPTION_ID is defined in ./templates/core/private.env"}

set -o pipefail
set -o nounset
# set -o xtrace

SERVICE_BUS_NAMESPACE="sb-${TRE_ID}"
if [[ -z ${PUBLIC_DEPLOYMENT_IP_ADDRESS:-} ]]; then
  IPADDR=$(curl ipecho.net/plain; echo)
else
  IPADDR=${PUBLIC_DEPLOYMENT_IP_ADDRESS}
fi

echo "Adding local IP Address to ${COSMOSDB_ACCOUNT_NAME}. This may take a while . . . "
az cosmosdb update \
  --name ${COSMOSDB_ACCOUNT_NAME} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --ip-range-filter ${IPADDR}

echo "Adding local IP Address to ${SERVICE_BUS_NAMESPACE}."
az servicebus namespace network-rule add \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --namespace-name ${SERVICE_BUS_NAMESPACE} \
  --ip-address ${IPADDR} \
  --action Allow

# Get the object id of the currently logged-in identity
if [[ ! -z ${ARM_CLIENT_ID:-} ]]; then
  # if environment includes a SP with subscription access, then we should use that.
  LOGGED_IN_OBJECT_ID=$(az ad sp show --id ${ARM_CLIENT_ID} --query objectId -o tsv)
else
  LOGGED_IN_OBJECT_ID=$(az ad signed-in-user show --query objectId -o tsv)
fi

# Assign Role Permissions.
az role assignment create \
    --role "Azure Service Bus Data Sender" \
    --assignee ${LOGGED_IN_OBJECT_ID} \
    --scope ${SERVICE_BUS_RESOURCE_ID}

az role assignment create \
    --role "Azure Service Bus Data Receiver" \
    --assignee ${LOGGED_IN_OBJECT_ID} \
    --scope ${SERVICE_BUS_RESOURCE_ID}

az role assignment create \
    --role "Contributor" \
    --assignee ${LOGGED_IN_OBJECT_ID} \
    --scope ${STATE_STORE_RESOURCE_ID}

if [[ -z ${ARM_CLIENT_ID:-} ]]; then
  # Configure SP for local resource processor debugging (Porter can't use local creds)
  echo "Configuring Service Principal for Resource Processor debugging..."
  RP_TESTING_SP=$(az ad sp create-for-rbac --name "ResourceProcessorTesting-${TRE_ID}" --role Owner --scopes /subscriptions/${AZURE_SUBSCRIPTION_ID} -o json)
  RP_TESTING_SP_APP_ID=$(echo ${RP_TESTING_SP} | jq -r .appId)
  RP_TESTING_SP_PASSWORD=$(echo ${RP_TESTING_SP} | jq -r .password)
else
  # no need to create a new sp if we already have one available
  RP_TESTING_SP_APP_ID=${ARM_CLIENT_ID}
  RP_TESTING_SP_PASSWORD=${ARM_CLIENT_SECRET}
fi

# Assign Service Bus permissions to the Resource Processor SP
az role assignment create \
    --role "Azure Service Bus Data Sender" \
    --assignee ${RP_TESTING_SP_APP_ID} \
    --scope ${SERVICE_BUS_RESOURCE_ID}

az role assignment create \
    --role "Azure Service Bus Data Receiver" \
    --assignee ${RP_TESTING_SP_APP_ID} \
    --scope ${SERVICE_BUS_RESOURCE_ID}

# Write the appId and secret to the private.env file which is used for RP debugging
# First check if the env vars are there already and delete them
sed -i '/ARM_CLIENT_ID/d' ./templates/core/private.env
sed -i '/ARM_CLIENT_SECRET/d' ./templates/core/private.env

# Append them to the TRE file so that the Resource Processor can use them
tee -a ./templates/core/private.env <<EOF
ARM_CLIENT_ID=${RP_TESTING_SP_APP_ID}
ARM_CLIENT_SECRET=${RP_TESTING_SP_PASSWORD}
EOF

echo "Local debugging configuration complete. The vscode debug profiles for the API and Resource Processor are ready to use."
