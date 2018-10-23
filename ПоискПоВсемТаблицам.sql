CREATE PROC [dbo].[SearchAllTables] 
(
	@SearchStr nvarchar(100)
)
AS
BEGIN
DECLARE @Results TABLE(ColumnName nvarchar(370), ColumnValue nvarchar(3630))

SET NOCOUNT ON

DECLARE @TableName nvarchar(256)
DECLARE @ColumnName nvarchar(128)
DECLARE @DataType nvarchar(128)

DECLARE @SearchStr2 nvarchar(110)
DECLARE @SearchDecimal decimal(38,19)
DECLARE @Query nvarchar(4000)
SET @SearchStr2 = QUOTENAME('%' + @SearchStr + '%', '''')
SET @SearchDecimal = CASE WHEN ISNUMERIC(@SearchStr) = 1 THEN CONVERT(decimal(38,19), @SearchStr) ELSE NULL END
PRINT '@SearchStr2: ' + @SearchStr2
PRINT '@SearchDecimal: ' + CAST(@SearchDecimal AS nvarchar)

SET @TableName = ''
WHILE @TableName IS NOT NULL
BEGIN
    SET @ColumnName = ''
    SET @TableName = 
    (
        SELECT MIN(QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME))
        FROM    INFORMATION_SCHEMA.TABLES
        WHERE       TABLE_TYPE = 'BASE TABLE'
            AND QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME) > @TableName
            AND OBJECTPROPERTY(
                    OBJECT_ID(
                        QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
                         ), 'IsMSShipped'
                           ) = 0
    )

    WHILE (@TableName IS NOT NULL) AND (@ColumnName IS NOT NULL)
    BEGIN
		SET @ColumnName =
		(
			SELECT MIN(QUOTENAME(COLUMN_NAME))
				    DATA_TYPE
			FROM    INFORMATION_SCHEMA.COLUMNS
			WHERE       TABLE_SCHEMA    = PARSENAME(@TableName, 2)
				AND TABLE_NAME  = PARSENAME(@TableName, 1)
				AND DATA_TYPE IN ('char', 'varchar', 'nchar', 'nvarchar',
								  'int', 'bigint', 'tinyint', 'numeric', 'decimal')
				AND QUOTENAME(COLUMN_NAME) > @ColumnName
		)
		SET @DataType =
		(
			SELECT DATA_TYPE
			FROM    INFORMATION_SCHEMA.COLUMNS
			WHERE       TABLE_SCHEMA    = PARSENAME(@TableName, 2)
				AND TABLE_NAME  = PARSENAME(@TableName, 1)
				AND QUOTENAME(COLUMN_NAME) = @ColumnName
		)
		PRINT @TableName + '.' + @ColumnName + ' (' + @DataType + ')'

        IF @ColumnName IS NOT NULL
        BEGIN
			IF @DataType IN ('int', 'bigint', 'tinyint', 'numeric', 'decimal')
			BEGIN
				IF @SearchDecimal IS NOT NULL
				BEGIN
					SET @Query = 'SELECT ''' + @TableName + '.' + @ColumnName + ''', LEFT(CAST(' + @ColumnName + ' AS nvarchar(110)), 3630) ' +
								 'FROM ' + @TableName + ' (NOLOCK) ' +
								 ' WHERE ' + @ColumnName + ' = ' + CAST(@SearchDecimal AS nvarchar)
					PRINT '    ' + @Query
					INSERT INTO @Results
					EXEC (@Query)
				END
			END
			ELSE
			BEGIN
				SET @Query = 'SELECT ''' + @TableName + '.' + @ColumnName + ''', LEFT(' + @ColumnName + ', 3630) ' +
							 'FROM ' + @TableName + ' (NOLOCK) ' +
							 ' WHERE ' + @ColumnName + ' LIKE ' + @SearchStr2
				PRINT '    ' + @Query
				INSERT INTO @Results
				EXEC (@Query)
			END
        END
    END 
END

SELECT ColumnName, ColumnValue FROM @Results
END
GO