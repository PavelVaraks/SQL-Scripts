function get-DiskVolumes
{
    param(
        [string]$ComputerName=$env:COMPUTERNAME,
        [switch]$Raw
    )
    $Filter = @{Expression={$_.Name};Label="DiskName"}, `
              @{Expression={$_.Label};Label="Label"}, `
              @{Expression={$_.FileSystem};Label="FileSystem"}, `
              @{Expression={[int]$($_.BlockSize/1KB)};Label="BlockSizeKB"}, `
              @{Expression={[int]$($_.Capacity/1GB)};Label="CapacityGB"}, `
              @{Expression={[int]$($_.Freespace/1GB)};Label="FreeSpaceGB"},
              @{Expression={[Math]::Round([decimal]$(($_.Freespace/1GB)/(($_.Capacity/1GB)))*100)};Label="FreeSpace%"}
    if($Raw){Get-WmiObject Win32_Volume -ComputerName $ComputerName | Select-Object $Filter}
    else{Get-WmiObject Win32_Volume -ComputerName $ComputerName | Format-Table $Filter -AutoSize}
}
get-DiskVolumes
