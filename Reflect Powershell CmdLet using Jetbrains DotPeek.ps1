function Reflect-Cmdlet {  
    param([Management.Automation.CommandInfo]$command)  
    if ($input) {  
        trap { $_; break }  
        $command = $input | select -first 1  
    }      
         
    # resolve to command if this is an alias  
    while ($command.CommandType -eq "Alias") {  
        $command = Get-Command ($command.definition)  
    }  
      
    $name = $command.ImplementingType      
    $DLL = $command.DLL  
      
    if (-not (gcm reflector.exe -ea silentlycontinue)) {  
        throw "I can't find Reflector.exe in your path." 
    }  
       
    reflector /select:$name $DLL 
} 

function Peek-Cmdlet {  
    param(
        [Management.Automation.CommandInfo]$command
    )
      
    if ($input) {  
        trap { $_; break }  
        $command = $input | select -first 1  
    }
         
    # resolve to command if this is an alias  
    while ($command.CommandType -eq "Alias") {  
        $command = Get-Command ($command.definition)  
    }  
      
    $name = $command.ImplementingType      
    $dll = $command.DLL

    $inspector = "D:\01_Distrib\dotPeek32.2018.1.2.exe"  
    & $inspector /select=$dll!$name
} 
get-command Install-ADServiceAccount | Peek-Cmdlet