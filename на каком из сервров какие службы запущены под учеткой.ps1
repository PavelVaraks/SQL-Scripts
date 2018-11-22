<#
На каком из серверов $s(Городец), какие службы запущены под учеткой $u
Powershell, под привилегированной УЗ
Выполняется не быстро
#>

cls
[string]$u="dpc\n5201_svc_sqlais"
[string]$s="n5201-AIS*"
[array]$computers=Get-ADComputer -Filter { name -like $s} | select name
foreach ($computerName in $computers)`
{
Write-host "Проверяю " $computername.name
Get-WmiObject -Class Win32_Service -ComputerName $computerName.name |`
? { $_.StartName -eq $u }|`
ft DisplayName, StartName, State, @{name="ComputerName";expression={$computerName.name}}
}