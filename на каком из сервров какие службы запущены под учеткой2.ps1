<#
Ответ на вопрос где используется в качестве УЗ под запуск служб:

Powershell, под привилегированной УЗ

На каком из серверов $s(Городец), какие службы запущены под учеткой $u

Выполняется не быстро
#>
cls
[string]$u="dpc\9965_svc_sql_prom"
[string]$s="*"
[array]$computers=Get-ADComputer -Filter { name -like $s 
-and Description -notlike "Failover cluster virtual network name account"
-and OperatingSystem -like "*Windows*"} | select name
$computers
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
