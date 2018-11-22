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


#ServerName
$ServerName="N5001-AIS275"
#Меняет пароль у учетки dbsnmp
#Показывает имена всех пользовательских баз
$Backup="declare @command nvarchar(max)
set @command= 
'USE ?
IF DB_ID()> 4
BEGIN
declare @database nvarchar(100) 
set @database= DB_NAME()
declare @Path nvarchar(max)
declare @name nvarchar(100)
declare @servername nvarchar(100)
set @servername = convert(nvarchar(200), SERVERPROPERTY(''ServerName''),2)
set @name = @database +''-Full Database Backup''
set @Path = ''\\dpc.tax.nalog.ru\root\GRs\PK\gr015\''+@servername+''\SM-1115\''+@database+''.bak''
BACKUP DATABASE @database
TO  DISK =  @path
WITH  COPY_ONLY
,NOFORMAT
,NOINIT
,NAME = @name
,SKIP
,NOREWIND
,NOUNLOAD
,COMPRESSION
,buffercount = 16
,STATS = 5
END'
EXEC sp_MSforeachdb @command
"



Invoke-Sqlcmd2 -ServerInstance $ServerName -Query $ViewBase 


$ServerName="N5001-AIS555"
Invoke-Sqlcmd2 -ServerInstance $ServerName -Query $ViewBase
