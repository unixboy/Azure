    
     
#Select-AzureRMSubscription -SubscriptionName CALM-WFM-Production


$imageURI="https://vmimage.blob.core.windows.net/vhd/osDisk.7b4e9865-70cd-4e14-83a2-d012e5d1a89a.vhd"
    $rgName = "powershell2temp" # must be the same as the storage account
    $location = "West US"
    $vnetName = "powershell2temp-vnet"
    $vnetRg = "powershell2temp"

    $cred = Get-Credential
    $storageAccName = "vmimagesbase" # must be the same as the image source
    $vmName = "PRODPSVM1"
    $vmSize = "Standard_Ds2_v2"
    $computerName = $vmName
    $osDiskName = "${vmName}OsDisk1"
    $skuName = "Premium_LRS"
    $nicName = "${vmName}Nic1"
    $ipName = "${vmName}Pip1"
 
    $storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $rgName -AccountName $storageAccName
    $vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize
    $pip = New-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rgName -Location $location `
    -AllocationMethod Dynamic
    $vnet = Get-AzureRmVirtualNetwork -Name  $vnetName -ResourceGroupName $vnetRg
    $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $vnetRg -Location $location `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
    $vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $computerName `
        -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
    $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
    $osDiskUri = '{0}vhds/{1}-{2}.vhd' `
        -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName
    $vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri `
        -CreateOption fromImage -SourceImageUri $imageURI -Windows
    New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm
 

