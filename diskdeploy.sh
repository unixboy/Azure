#!/bin/sh

set -e

# Name of your Azure subscription
subscriptionName=""
# Name of the resource group to use
resourceGroupName=""
# Name of the storage account to copy the disk images into
storageAccountName=""
# Name of the container within the storage account to copy the disk images into
containerName="vm-images"
# Version tp copy
version="1-0-0"

# Ensure CLI is in ARM mode
a#zure config mode arm

# Log in to Azure
#azure login

# Set the current suscription
#azure account set $subscriptionName

# Obtain the access key for the storage account
storageAccountKey=$(azure storage account keys list -g $resourceGroupName $storageAccountName | grep 'Primary' | sed -e 's/^.*Primary: \(.*\)$/\1/')

# Ensure that the container exists
azure storage container create -a $storageAccountName -k $storageAccountKey $containerName || true

# Start copying the Management Node image
azure storage blob copy start --dest-account-name $storageAccountName --dest-account-key $storageAccountKey --dest-container $containerName --dest-blob "disk1-$version.vhd" "https://location.blob.core.windows.net/vhds/$version/disk1.vhd"

# Start copying the Conferencing Node image
azure storage blob copy start --dest-account-name $storageAccountName --dest-account-key $storageAccountKey --dest-container $containerName --dest-blob "disk2-$version.vhd" "https://location.blob.core.windows.net/vhds/$version/disk2.vhd"

# Wait for the image to finish copying
while azure storage blob copy show --json -a $storageAccountName -k $storageAccountKey --container $containerName --blob "disk1-$version.vhd" | grep -q '"copyStatus": "pending"'; do sleep 10; done
azure storage blob copy show --json -a $storageAccountName -k $storageAccountKey --container $containerName --blob "disk1-$version.vhd"

# Wait for the image to finish copying
while azure storage blob copy show --json -a $storageAccountName -k $storageAccountKey --container $containerName --blob "disk2-$version.vhdd" | grep -q '"copyStatus": "pending"'; do sleep 10; done
azure storage blob copy show --json -a $storageAccountName -k $storageAccountKey --container $containerName --blob "disk2-$version.vhd"

# Print out the prepared disk image URLs for later use
echo "Prepared disk image: https://$storageAccountName.blob.core.windows.net/$containerName/disk1-$version.vhd"
echo "Prepared disk image: https://$storageAccountName.blob.core.windows.net/$containerName/disk2-$version.vhd"
