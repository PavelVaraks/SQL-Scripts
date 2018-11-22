Invoke-Command -ComputerName n7701-lsn023 -ScriptBlock {

$localhost=get-content env:computername
write-host "Запускаем скрипт на сервере" $localhost

$sqlserver = "localhost"
$SqlCatalog = "master"
$sqlConnection = New-Object system.data.SqlClient.Sqlconnection
$sqlConnection.ConnectionString="Server=$sqlserver; Database=$SqlCatalog; Integrated Security=SSPI; MultiSubnetFailover=TRUE"
$sqlConnection.Open()
$sqlcmd=$sqlConnection.CreateCommand()
$sqlcmd.CommandText="select DB_name()+'\'+@@servername+' подключение установлено в '+convert(nvarchar,getdate(),14)"
$objReader=$sqlcmd.ExecuteReader()
while ($objReader.read()){
echo $objReader.GetValue(0)
}
$objReader.Close()
}