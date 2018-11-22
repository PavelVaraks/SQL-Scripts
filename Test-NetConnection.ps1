Invoke-Command -ComputerName N7701-PPK209 -ScriptBlock {
Test-NetConnection -ComputerName N7701-PPK160 -Port 3343
Test-NetConnection -ComputerName N7701-PPK161 -Port 3343
}
