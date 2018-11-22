function Invoke-Sqlcmd2 

{ 
    [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
    [Parameter(Position=1, Mandatory=$false)] [string]$Database, 
    [Parameter(Position=2, Mandatory=$false)] [string]$Query, 
    [Parameter(Position=3, Mandatory=$false)] [string]$Username, 
    [Parameter(Position=4, Mandatory=$false)] [SecureString]$Password, 
    [Parameter(Position=5, Mandatory=$false)] [Int32]$QueryTimeout=600, 
    [Parameter(Position=6, Mandatory=$false)] [Int32]$ConnectionTimeout=15, 
    [Parameter(Position=7, Mandatory=$false)] [ValidateScript({test-path $_})] [string]$InputFile, 
    [Parameter(Position=8, Mandatory=$false)] [ValidateSet("DataSet", "DataTable", "DataRow")] [string]$As="DataRow" 
    ) 
 
    if ($InputFile) 
    { 
        $filePath = $(resolve-path $InputFile).path 
        $Query =  [System.IO.File]::ReadAllText("$filePath") 
    } 
 
    $conn=new-object System.Data.SqlClient.SQLConnection 
      
    if ($Username) 
    { $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout } 
    else 
    { $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout } 
 
    $conn.ConnectionString=$ConnectionString 
     
    if ($PSBoundParameters.Verbose) 
    { 
        $conn.FireInfoMessageEventOnUserErrors=$true 
        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-Verbose "$($_)"} 
        $conn.add_InfoMessage($handler) 
    } 
     
    $conn.Open() 
    $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn) 
    $cmd.CommandTimeout=$QueryTimeout 
    $ds=New-Object system.Data.DataSet 
    $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd) 
    [void]$da.fill($ds) 
    $conn.Close() 
    switch ($As) 
    { 
        'DataSet'   { Write-Output ($ds) } 
        'DataTable' { Write-Output ($ds.Tables) } 
        'DataRow'   { Write-Output ($ds.Tables[0]) } 
    } 
 
}



$ServerName=$Server

$FindPrincipalMirror='declare @principalMirror nvarchar(200) 
set @principalMirror=(select distinct mirroring_partner_instance from sys.database_mirroring
where mirroring_partner_instance is not null)
select @principalMirror'

$FindMirror='declare @principalMirror nvarchar(200) 
IF EXISTS (select distinct mirroring_partner_instance from sys.database_mirroring
where mirroring_partner_instance is not null and mirroring_role_desc=''MIRROR'')
set @principalMirror=@@Servername
select @principalMirror'


$SuspendMirror='declare @effect nvarchar(max)
set @effect =
--Остановить синхронизацию
''SUSPEND''
--Продолжить синхронизацию
--''RESUME''
--меняет роли у серверов
--''FAILOVER''
--Переключает Operating mode в Синхронный режим
--''SAFETY FULL''
--Переключает Operating mode в Асинхронный режим
--''SAFETY OFF''
declare @command nvarchar(max)
declare @name nvarchar(max)
DECLARE db_cursor CURSOR FOR
SELECT name
FROM master.dbo.sysdatabases as d
left join sys.database_mirroring as m on m.database_id=d.dbid
WHERE d.name NOT IN (''master'',''model'',''msdb'',''tempdb'')
and m.mirroring_guid is not null
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @name
WHILE @@FETCH_STATUS = 0
BEGIN
set @command = ''ALTER DATABASE ''+@name+'' SET PARTNER ''+@effect
print @command
exec  sys.sp_executesql  @command
FETCH NEXT FROM db_cursor INTO @name
END
CLOSE db_cursor
DEALLOCATE db_cursor'


$resumeMirror='declare @effect nvarchar(max)
set @effect =
--Остановить синхронизацию
--''SUSPEND''
--Продолжить синхронизацию
''RESUME''
--меняет роли у серверов
--''FAILOVER''
--Переключает Operating mode в Синхронный режим
--''SAFETY FULL''
--Переключает Operating mode в Асинхронный режим
--''SAFETY OFF''
declare @command nvarchar(max)
declare @name nvarchar(max)
DECLARE db_cursor CURSOR FOR
SELECT name
FROM master.dbo.sysdatabases as d
left join sys.database_mirroring as m on m.database_id=d.dbid
WHERE d.name NOT IN (''master'',''model'',''msdb'',''tempdb'')
and m.mirroring_guid is not null
OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @name
WHILE @@FETCH_STATUS = 0
BEGIN
set @command = ''ALTER DATABASE ''+@name+'' SET PARTNER ''+@effect
print @command
exec  sys.sp_executesql  @command
FETCH NEXT FROM db_cursor INTO @name
END
CLOSE db_cursor
DEALLOCATE db_cursor'

$SqlMirrorStatus='select count(*) from sys.database_mirroring where mirroring_state_desc!=''SYNCHRONIZED'''

Add-Type -assembly System.Windows.Forms
$currentuser=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text ='Перезагрузка Mirror'
$main_form.Width = 400
$main_form.Height = 250
$main_form.AutoSize = $true
$main_form.StartPosition = "CenterScreen"

$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Width = 400
$TabControl.Height = 250
$TabControl.AutoSize = $true
 
$wshell = New-Object -ComObject Wscript.Shell


$reboot_form = New-Object System.Windows.Forms.Form
$reboot_form.Text ='Reboot'
$reboot_form.Width = 50
$reboot_form.Height = 50
$reboot_form.AutoSize = $true
$reboot_form.StartPosition = "CenterScreen"
 
# Функции отключения кнопок
 
function buttonoff {
$CloseWindowButton.Enabled = $false
$Checkbutton.Enabled = $false
$RebootServer.Enabled = $false
}
 
function buttonon {
$Checkbutton.Enabled = $true
$RebootServer.Enabled = $true
$CloseWindowButton.Enabled = $true
}
 
####### Логирование
 
$currentdate=Get-Date
$currentuser=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$body="$currentdate $currentuser"
 <#
Function sendlog{
Send-MailMessage -SmtpServer "" -From "1С-Tool <1c-tool@crocusgroup.ru>" -To "<>" -Subject "1C-Tool Action Log" -Body $body -Encoding UTF8
$getcontentlog=Get-Content \\fs\1c$\tool\1ctoollog.txt
Set-Content \\fs\1c$\Tool\1ctoollog.txt $body,$getcontentlog
}
 #>
$MainMirroringPage = New-Object System.Windows.Forms.TabPage
$MainMirroringPage.AutoSize = $true
#$MainMirroringPage.AutoSizeMode = "GrowAndShrink"
$MainMirroringPage.Text = 'Mirroring'
function  searchMirror {
$Checkbutton.Enabled = $false 
$RebootServer.Enabled = $false                 
$MainMirroringListBox.Clear()
$name = $ServerNameBox.Text
$MainMirroringListBox.ForeColor ='Black' 
if 
    ( Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue ) 
        {
    $MainMirroringListBox.AppendText("`n" + "$name is up")
    IF 
    ([System.Net.Dns]::GetHostByName($name) | Where-Object Hostname -Like "*idmz*")
        {
            $MainMirroringListBox.ForeColor ='red'

            $MainMirroringListBox.AppendText("`n" + "Это сервер IDMZ, перезагружаем руками")

            $Checkbutton.Enabled = $true
        }
ELSE
{
#[void] $MainMirroringListBox.Items.Add("Это сервер домена DPC")

#[void] $MainMirroringListBox.Items.Add("Проверим запущена ли служба MS SQL")
$MSSQL=Get-Service -Name MSSQLSERVER -ComputerName $name
IF
($MSSQL.status -ne "Running")
{
$MainMirroringListBox.ForeColor ='red'
[void] $MainMirroringListBox.AppendText("`n" + "Это не MS SQL Server или служба остановлена")
$Checkbutton.Enabled = $true
Start-Sleep 2
}
Else 
{
$lastbootup=Invoke-Command -ComputerName $name -ScriptBlock {Get-WmiObject win32_operatingsystem | Select-Object @{LABEL='LastBootUpTime'
;EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}}
$lastbootuptime=$lastbootup.LastBootUpTime
$lastbootuptime
$lastbootup
$now = Get-Date 
$now
$Uptime
$Uptime = $now - $lastbootuptime
$Uptime
$d = $Uptime.Days
$h = $Uptime.Hours
#$m = $uptime.Minutes
#$ms= $uptime.Milliseconds
$a = "Сервер работает: {0} Days, {1} Hours" -f $d,$h,$m,$ms
$MainMirroringListBox.AppendText("`n" + "$a")
$RebootPending=Invoke-Command -ComputerName $name -ScriptBlock {
 if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
 if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
 if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { return $true }
 try { 
   $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
   $status = $util.DetermineIfRebootPending()
   if(($status -ne $null) -and $status.RebootPending){
     return $true
   }
 }catch{}
return "Перезагрузка не требуется"

}
$RebootServer.Enabled = $false
IF ($RebootPending -eq $true)
{
$RebootPending="Требуется перезагрузить"
$RebootServer.Enabled = $true
}
$RebootServer.Enabled = $true
$MainMirroringListBox.AppendText("`n" + $RebootPending)
#[void] $MainMirroringListBox.Items.Add("Служба MS SQL запущена!")
[STRING]$PrincipalMirror
$MirrorSRV=Invoke-Sqlcmd2 -ServerInstance $name -Query $FindMirror 
$MirrorSRVName=$MirrorSRV.Column1
IF ($MirrorSRVName -eq $name)
{
$PrincipalMirror=Invoke-Sqlcmd2 -ServerInstance $name -Query $FindPrincipalMirror
$PrincipalMirrorName=$PrincipalMirror.Column1
$MainMirroringListBox.ForeColor ='Green'
$MainMirroringListBox.AppendText("`n" + "Cервер $name - Зеркало,можно перезагрузить в рабочее время!")
$Checkbutton.Enabled=$true

}
ELSE
{
$MainMirroringListBox.ForeColor ='red'
$MainMirroringListBox.AppendText("`n" + "Это основной сервер или зеркалирование не настроено")
$CloseWindowButton.Enabled = $true
$RebootServer.Enabled = $false
$Checkbutton.Enabled = $true
}

}
}
}
else {
$MainMirroringListBox.AppendText("`n" + "`n" + "$name is down");
$Checkbutton.Enabled = $true
}
}
     
$ServerNameBox = New-Object System.Windows.Forms.TextBox
$ServerNameBox.Location = New-Object System.Drawing.Size(10,30) 
#$ServerNameBox.Size = New-Object System.Drawing.Size(250,20) 
$ServerNameBox.AutoSize = $true
#$ServerNameBox.AcceptsReturn = $true
$MainMirroringPage.Controls.Add($ServerNameBox)
#$ServerNameBox.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
 #   {searchMirror
#$checkedName = $ServerNameBox.Text}}) 
 
$Checkbutton = New-Object System.Windows.Forms.Button
$Checkbutton.Location = New-Object System.Drawing.Size(290,28)
#$Checkbutton.Size = New-Object System.Drawing.Size(75,23)
$Checkbutton.AutoSize = $true
$Checkbutton.Text = "Проверить"
$Checkbutton.Add_Click({searchMirror 
Set-Variable -Name checkedName -Value ($ServerNameBox.Text) -Scope Global})
$MainMirroringPage.Controls.Add($Checkbutton)

 #CloseWindowButton
$CloseWindowButton = New-Object System.Windows.Forms.Button
$CloseWindowButton.Location = New-Object System.Drawing.Size(300,200)
$CloseWindowButton.Size = New-Object System.Drawing.Size(75,23)
$CloseWindowButton.Text = "Закрыть"
$CloseWindowButton.Enabled = $True
$CloseWindowButton.Add_click({$main_form.Close()})
$MainMirroringPage.Controls.Add($CloseWindowButton)

 #RebootServer
$RebootServer = New-Object System.Windows.Forms.Button
$RebootServer.Location = New-Object System.Drawing.Size(10,200)
$RebootServer.Size = New-Object System.Drawing.Size(75,23)
$RebootServer.Text = "RebootNow"
$RebootServer.Enabled = $false
$RebootServer.Add_Click({
 
buttonoff
$name = $ServerNameBox.Text
IF ($checkedName -eq $name){
#[void] $MainMirroringListBox.Items.Clear()
$PrincipalMirror=Invoke-Sqlcmd2 -ServerInstance $name -Query $FindPrincipalMirror
$PrincipalMirrorName=$PrincipalMirror.Column1
[STRING]$PrincipalMirror
$MirrorSRV=Invoke-Sqlcmd2 -ServerInstance $name -Query $FindMirror 
$MirrorSRVName=$MirrorSRV.Column1
IF ($MirrorSRVName -eq $name){
$MainMirroringListBox.AppendText("`n" + "Останавливаем Репликацию на сервере $PrincipalMirrorName")
Invoke-Sqlcmd2 -ServerInstance $PrincipalMirrorName -Query $SuspendMirror
$MirrorStatus=Invoke-Sqlcmd2 -ServerInstance $PrincipalMirrorName -Query $SqlMirrorStatus
$MirrorStatusInt=$MirrorStatus.Column1
IF ($MirrorStatusInt -ne 0){
$MainMirroringListBox.AppendText("`n" + "Репликация остановленна")}

Invoke-Command -ComputerName $name -ScriptBlock{
Stop-Service  -name MSSQLSERVER  -Force }
Start-Sleep 5
Restart-Computer -ComputerName $name -Force
$MainMirroringListBox.AppendText("`n" + "Сервер $name отправлен в перезагрузку")
DO
{
if
(Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue)
{
    $MainMirroringListBox.AppendText("`n" + "Сервер $name доступен")
    $MSSQL=Get-Service -Name MSSQLSERVER -ComputerName $name

    IF

    ($MSSQL.status -eq "Running")

    {

        $MainMirroringListBox.AppendText("`n" + "Служба запущена")

        Start-Sleep 10

        $MainMirroringListBox.AppendText("`n" + "Восстанавливаем репликацию зеркало")

        Invoke-Sqlcmd2 -ServerInstance $PrincipalMirrorName -Query $resumeMirror

        $MirrorStatus=Invoke-Sqlcmd2 -ServerInstance $PrincipalMirrorName -Query $SqlMirrorStatus

        $MirrorStatusInt=$MirrorStatus.Column1

        IF ($MirrorStatusInt -eq 0)

        {

            $MainMirroringListBox.AppendText("`n" + "Зеркало Восстановлено")

            Invoke-Sqlcmd2 -ServerInstance $PrincipalMirrorName -Query $resumeMirror

            $RebootServer.Enabled = $false

        }

    }

    Else 

    {

        $time=(get-date -DisplayHint time)

        $MainMirroringListBox.AppendText("`n" + "$time")

        $MainMirroringListBox.AppendText("`n" + "Служба не запущена")

        Start-Sleep 10

        #$MainMirroringListBox.Items.Clear()
}
}
ELSE
{$MainMirroringListBox.AppendText("`n" + "Сервер недоступен, через 10 секунд опросим снова")
Start-Sleep 10
}
}
WHILE ($MSSQL.status -ne "Running")
buttonon
$RebootServer.Enabled = $false
$CloseWindowButton.Enabled = $true
}
}
ELSE{$MainMirroringListBox.ForeColor ='red'
#$MainMirroringListBox.AppendText.Clear()
$name=$ServerNameBox.Text
[void] $MainMirroringListBox.AppendText("`n" + "Мы проверяли $checkedName, а хочешь перезагрузить $name - Ай-ай!")
$CloseWindowButton.Enabled = $true
$Checkbutton.Enabled = $true
}
}     
)

$MainMirroringPage.Controls.Add($RebootServer)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,10) 
$objLabel.Size = New-Object System.Drawing.Size(230,20) 
$objLabel.Text = "Введите имя сервера:"
$MainMirroringPage.Controls.Add($objLabel) 
$MainMirroringListBox = New-Object System.Windows.Forms.RichTextBox 
$MainMirroringListBox.Multiline =$true
$MainMirroringListBox.ReadOnly=$true
$MainMirroringListBox.ScrollBars="Vertical"
$MainMirroringListBox.Location = New-Object System.Drawing.Size(10,60) 
$MainMirroringListBox.Size = New-Object System.Drawing.Size(600,100) 
$MainMirroringListBox.Height = 140
$MainMirroringPage.Controls.Add($MainMirroringListBox) 
$TabControl.Controls.Add($MainMirroringPage)
$TabControl.Location  = New-Object System.Drawing.Point(0,0)
$main_form.Controls.add($TabControl)
$main_form.ShowDialog()
$reboot_form.Controls.add($objlavel)
#$reboot_form.ShowDialog()

