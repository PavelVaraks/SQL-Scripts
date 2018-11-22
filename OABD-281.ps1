clear
[string]$Test=''
$test.GetType().FullName
$test=Get-ClusterGroup -Cluster "N5001-AIS506" | Where-Object {$_.IsCoreGroup -eq $false} | Get-ClusterOwnerNode | ft ClusterObject,OwnerNodes
write-host $Test

Get-Variable $test