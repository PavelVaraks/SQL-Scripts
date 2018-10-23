function Invoke-Sqlcmd2 
{ 
    [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
    [Parameter(Position=1, Mandatory=$false)] [string]$Database, 
    [Parameter(Position=2, Mandatory=$false)] [string]$Query, 
    [Parameter(Position=3, Mandatory=$false)] [string]$Username, 
    [Parameter(Position=4, Mandatory=$false)] [string]$Password, 
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
 
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text ='Перезагрузка Mirror'
$main_form.Width = 400
$main_form.Height = 300
$main_form.AutoSize = $true
$main_form.StartPosition = "CenterScreen"
 
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Width = 400
$TabControl.Height = 300
 
$wshell = New-Object -ComObject Wscript.Shell
 
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
Send-MailMessage -SmtpServer "mail.crocusgroup.ru" -From "1С-Tool <1c-tool@crocusgroup.ru>" -To "Ткаченко Егор <tkachenko@crocusgroup.ru>" -Subject "1C-Tool Action Log" -Body $body -Encoding UTF8
$getcontentlog=Get-Content \\fs\1c$\tool\1ctoollog.txt
Set-Content \\fs\1c$\Tool\1ctoollog.txt $body,$getcontentlog
}
 #>
$TabPage2 = New-Object System.Windows.Forms.TabPage
$TabPage2.Text = 'Mirroring'
 
function TypeInfo {
 
$getfilepath01=(Get-RDRemoteApp -ConnectionBroker cg-ts-001.net.crocusgroup.ru -CollectionName "1C" -alias "$alias")
$cutfilepath01=(Split-Path $getfilepath01.FilePath)
$filepath01=$cutfilepath01+$type
 
Set-RDRemoteApp -ConnectionBroker cg-ts-001.net.crocusgroup.ru -CollectionName "1C" -alias "$alias" -FilePath $filepath01 -FileVirtualPath $filepath01 -IconPath $filepath01
 
$body="$currentdate $currentuser    -   Тип клиента базы $x изменен на $type1"
 
sendlog
 
                     }
 
function  searchMirror {
 
$RebootServer.Enabled = $false                 
 
$objListBox2.Items.Clear()
 
$search = $ServerNameBox.Text
 
 $srv =
 foreach ($name in $search) {
if ( Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue ) {
[void] $objListBox2.Items.Add("$name is up")
IF ([System.Net.Dns]::GetHostByName($name) |Where-Object Hostname -Like "*idmz*"){
[void] $objListBox2.Items.Add("Это сервер IDMZ, перезагружаем руками")
}
ELSE
{
[void] $objListBox2.Items.Add("Это сервер домена DPC")
[void] $objListBox2.Items.Add("Проверим запущена ли служба MS SQL")
$MSSQL=Get-Service -Name MSSQLSERVER -ComputerName $name
IF
($MSSQL.status -ne "Running")
{
[void] $objListBox2.Items.Add("Служба не запущена")}
Else 
{
[void] $objListBox2.Items.Add("Служба MS SQL запущена!")
[STRING]$PrincipalMirror
$MirrorSRV=Invoke-Sqlcmd2 -ServerInstance $name -Query $FindMirror 
$MirrorSRVName=$MirrorSRV.Column1
IF ($MirrorSRVName -eq $name)
{
$PrincipalMirror=Invoke-Sqlcmd2 -ServerInstance $name -Query $FindPrincipalMirror
$PrincipalMirrorName=$PrincipalMirror.Column1
[void] $objListBox2.Items.Add("Этот сервер $name Mirror, можно перезагрузить в рабочее время!$PrincipalMirrorName")
buttonon
}
ELSE
{
[void] $objListBox2.Items.Add("Это основной сервер или зеркалирование не настроено, перезагрузка только в тех.окно!")
$CloseWindowButton.Enabled = $true
$RebootServer.Enabled = $false
$Checkbutton.Enabled = $true
}

}
}
}
else {
[void] $objListBox2.Items.Add("$name is down")
}
}
}
 
        
            
$ServerNameBox = New-Object System.Windows.Forms.TextBox
$ServerNameBox.Location = New-Object System.Drawing.Size(10,30) 
$ServerNameBox.Size = New-Object System.Drawing.Size(250,20) 
$ServerNameBox.Text = "n5201-ais269"
$ServerNameBox.AcceptsReturn = $true
$TabPage2.Controls.Add($ServerNameBox)
$ServerNameBox.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {searchMirror}}) 
 
$Checkbutton = New-Object System.Windows.Forms.Button
$Checkbutton.Location = New-Object System.Drawing.Size(290,28)
$Checkbutton.Size = New-Object System.Drawing.Size(75,23)
$Checkbutton.Text = "Проверить"
$Checkbutton.Add_Click({searchMirror})
$TabPage2.Controls.Add($Checkbutton)
 
 #CloseWindowButton
$CloseWindowButton = New-Object System.Windows.Forms.Button
$CloseWindowButton.Location = New-Object System.Drawing.Size(208,240)
$CloseWindowButton.Size = New-Object System.Drawing.Size(75,23)
$CloseWindowButton.Text = "Закрыть"
$CloseWindowButton.Enabled = $True
$CloseWindowButton.Add_click({$main_form.Close()})
$TabPage2.Controls.Add($CloseWindowButton)

 #RebootServer
$RebootServer = New-Object System.Windows.Forms.Button
$RebootServer.Location = New-Object System.Drawing.Size(108,240)
$RebootServer.Size = New-Object System.Drawing.Size(75,23)
$RebootServer.Text = "RebootServer"
$RebootServer.Enabled = $false
$RebootServer.Add_Click({
 
buttonoff
 
$search = $ServerNameBox.Text

[void] $objListBox2.Items.Clear()
$PrincipalMirror=Invoke-Sqlcmd2 -ServerInstance $search -Query $FindPrincipalMirror
$PrincipalMirrorName=$PrincipalMirror.Column1
[void] $objListBox2.Items.Add("Останавливаем Репликацию на сервере $PrincipalMirrorName")
Invoke-Sqlcmd2 -ServerInstance $PrincipalMirrorName -Query $SuspendMirror
$MirrorStatus=Invoke-Sqlcmd2 -ServerInstance $PrincipalMirrorName -Query $SqlMirrorStatus
$MirrorStatusInt=$MirrorStatus.Column1
IF ($MirrorStatusInt -ne 0){
[void] $objListBox2.Items.Add("Репликация остановленна")}
#Restart-Computer -ComputerName $search
[void] $objListBox2.Items.Add("Сервер $search отправлен в перезагрузку")
DO
{
$ping=ping $server
if
($ping -like "*(0%*")
{$objListBox2.Items.Add("Сервер $search доступен")

$objListBox2.Items.Add("Проверим доступен ли скуль")

$MSSQL=Get-Service -Name MSSQLSERVER -ComputerName $search

IF
($MSSQL.status -ne "Running")
{
$objListBox2.Items.Add("Служба не запущена")}
Else 
{
$objListBox2.Items.Add("Служба запущена")
Start-Sleep 1
$objListBox2.Items.Add("Восстанавливаем репликацию зеркало")
Invoke-Sqlcmd2 -ServerInstance $PrincipalMirrorName -Query $resumeMirror
$MirrorStatus=Invoke-Sqlcmd2 -ServerInstance $PrincipalMirrorName -Query $SqlMirrorStatus
$MirrorStatusInt=$MirrorStatus.Column1
IF ($MirrorStatusInt -eq 0)
{
$objListBox2.Items.Add("Зеркало Восстановлено")}
ELSE
{$objListBox2.Items.Add("Репликация не восстановлена, пробуем еще раз")
Invoke-Sqlcmd2 -ServerInstance $PrincipalMirror.Column1 -Query $resumeMirror
}
}
}
ELSE
{$objListBox2.Items.Add("Сервер недоступен, через 10 секунд опросим снова")
Start-Sleep 10
}
}
WHILE ($MSSQL.status -ne "Running")



buttonon
 
$CloseWindowButton.Enabled = $true
}        
)
 
 
$TabPage2.Controls.Add($RebootServer)
 
$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,10) 
$objLabel.Size = New-Object System.Drawing.Size(230,20) 
$objLabel.Text = "Введите имя сервера:"
$TabPage2.Controls.Add($objLabel) 
$objListBox2 = New-Object System.Windows.Forms.ListBox 
$objListBox2.Location = New-Object System.Drawing.Size(10,60) 
$objListBox2.Size = New-Object System.Drawing.Size(600,100) 
$objListBox2.Height = 140
$TabPage2.Controls.Add($objListBox2) 
 
$TabControl.Controls.Add($TabPage2) # тип клиента
$TabControl.Location  = New-Object System.Drawing.Point(0,0)
 
$main_form.Controls.add($TabControl)
 
$main_form.ShowDialog()

