function Prepare-OEM

{
 [CmdletBinding()] 
param(

    [Parameter(Position=0, Mandatory=$true)] [string]$agentRsp 
     
)
Write-host "Blababla $agentRsp"
TRY {
IF (Get-Volume -DriveLetter H)
{
(Get-content "$agentRsp\agent.rsp") | ForEach-Object {$_ -replace "^ORACLE_HOSTNAME.*$","ORACLE_HOSTNAME=$env:computername.$env:userdnsdomain" } | Set-Content "$agentRsp\agent.rsp"

(Get-content "$agentRsp\agent.rsp") | ForEach-Object {$_ -replace "^AGENT_INSTANCE_HOME.*$","AGENT_INSTANCE_HOME=H:\D_AGENT\" } | Set-Content "$agentRsp\agent.rsp"

}
}
CATCH 
{
IF (Get-Volume -DriveLetter H)
{
(Get-content "$agentRsp\agent.rsp") | ForEach-Object {$_ -replace "^ORACLE_HOSTNAME.*$","ORACLE_HOSTNAME=$env:computername.$env:userdnsdomain" } | Set-Content "$agentRsp\agent.rsp"

(Get-content "$agentRsp\agent.rsp") | ForEach-Object {$_ -replace "^AGENT_INSTANCE_HOME.*$","AGENT_INSTANCE_HOME=D:\D_AGENT\" } | Set-Content "$agentRsp\agent.rsp"

}
}
}
Prepare-OEM