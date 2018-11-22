cls

Get-ADComputer -Filter { Description -like "Failover cluster virtual network name account"} | ft name

[string]$u="dpc\n7701_svc_sqlais"
[string]$s="*"
[array]$computers=Get-ADComputer -Filter { name -like $s} | select name

foreach ($computerName in $computers)`
{
TRY {
#Write-host $computerName.name
Get-WmiObject -Class Win32_Service -ComputerName $computerName.name -ErrorAction SilentlyContinue |`
? { $_.StartName -eq $u }|`
ft DisplayName, StartName, State, @{name="ComputerName";expression={$computerName.name}} -ErrorAction SilentlyContinue
}
CATCH{}
} 


[string]$s="*"
[array]$computers=Get-ADComputer -Filter { name -like "n5001-ais669" -and (Get-ADComputer -Filter { Description -notlike "Failover cluster virtual network name account"} | ft name) } | select name
$computer
#Get-Service -ComputerName

Get-ComputerInfo