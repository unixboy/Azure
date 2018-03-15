
Select-AzureRMSubscription -SubscriptionName <SubscriptionName>
Stop-AzureRmVM -ResourceGroupName RESG-Name -Name VM01dev 
Set-AzureRmVm -ResourceGroupName RESG-Name -Name VM01dev -Generalized
$vm = Get-AzureRmVM -ResourceGroupName RESG-Name -Name VM01dev -Status
$vm.Statuses
Save-AzureRmVMImage -ResourceGroupName RESG-Name -Name VM01dev -DestinationContainerName images -VHDNamePrefix test-vm.vhd
Save-AzureRmVMImage -ResourceGroupName RESG-Name -VMName VM01dev -DestinationContainerName images -VHDNamePrefix "VM-TEST"
