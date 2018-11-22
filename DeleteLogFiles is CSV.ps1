$servernames = import-CSV -Path "D:\N5001-AIS66X.csv"
foreach ($servername in $servernames)
{
ForEach-Object Invoke-Command -ComputerName $servername -ScriptBlock 
{
Get-ChildItem "D:\D_agent\agent_inst\sysman\emd\*.log" | Remove-Item -Force -Recurse
} 

}


