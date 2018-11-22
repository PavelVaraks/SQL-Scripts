cls
# Extract info from logs            
$allRDPevents = Get-WinEvent -FilterHashtable @{Logname = "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational" ; ID = 1149,1150,1148} -ErrorAction SilentlyContinue            
            
$RDPevents = @()              
foreach ($event in $allRDPevents)            
{            
    $result = $type = $null            
    # http://technet.microsoft.com/en-us/library/ee891195%28v=ws.10%29.aspx            
    switch ($event.ID)            
    {            
        1148 { $result = "failed"    }            
        1149 { $result = "succeeded" }            
        1150 { $result =  "merged"   }            
    }            
    $RDPevents += New-Object -TypeName PSObject -Property @{            
                    ComputerName = $env:computername            
                    User = $event.Properties[0].Value            
                    Domain = $event.Properties[1].Value            
                    SourceNetworkAddress = [net.ipaddress]$Event.Properties[2].Value            
                    TimeCreated = $event.TimeCreated            
                    Result = $result            
                }            
}            
            
# Display results            
$RDPevents | Sort-Object -Descending:$true -Property TimeCreated | Format-Table -AutoSize -Wrap     