<#
Ответ на вопрос где используется в качестве УЗ под запуск служб:

Powershell, под привилегированной УЗ

На каком из серверов $s(Городец), какие службы запущены под учеткой $u

Выполняется не быстро
#>

[string]$u="Local System"
[string]$s="n5001-ais*"
[array]$computers=Get-ADComputer -Filter { name -like $s 
-and Description -notlike "Failover cluster virtual network name account"
-and OperatingSystem -like "*Windows*"} | select name
$computers
foreach ($computerName in $computers)`
{
#Write-host $computerName.name
Get-WmiObject -Class Win32_Service -ComputerName $computerName.name -ErrorAction SilentlyContinue |`
? {$_.name -eq "D_agent" -or $_.name -eq "G_agent"}| ? {$_.startName -ne "DPC\N5201gMSA_OEM$" -or $_.startName -ne "DPC\N5001gMSA_OEM$"}|`
ft DisplayName, StartName, State, @{name="ComputerName";expression={$computerName.name}},@{name="OS_Version";expression={Invoke-Command $computerName.name -ScriptBlock { (gwmi win32_operatingsystem).caption }}} -ErrorAction SilentlyContinue

} 
