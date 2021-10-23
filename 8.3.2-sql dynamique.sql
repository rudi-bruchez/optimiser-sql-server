ALTER PROCEDURE Person.SearchContactsStatique
	@FirstName nvarchar(50) = NULL,
	@MiddleName nvarchar(50) = NULL,
	@LastName nvarchar(50) = NULL,
	@Suffix nvarchar(10) = NULL,
	@EmailAddress nvarchar(50) = NULL
AS BEGIN
	SET NOCOUNT ON

	IF COALESCE(@FirstName, @MiddleName, @LastName, 
			@Suffix, @EmailAddress) IS NULL BEGIN
		RAISERROR ('Vous devez saisir au moins un critère de recherche', 16, 10)
		RETURN -1
	END

	SELECT FirstName, MiddleName, LastName, Suffix, EmailAddress
	FROM Person.Contact
	WHERE 
		(LastName = @LastName OR @LastName IS NULL) AND
		(FirstName = @FirstName OR @FirstName IS NULL) AND
		(MiddleName = @MiddleName OR @MiddleName IS NULL) AND
		(Suffix = @Suffix OR @Suffix IS NULL) AND
		(EmailAddress = @EmailAddress OR @EmailAddress IS NULL)
	ORDER BY LastName, FirstName
	RETURN 0
END
GO
-- SQL dynamique

ALTER PROCEDURE Person.SearchContactsDynamique
	@FirstName nvarchar(50) = NULL,
	@MiddleName nvarchar(50) = NULL,
	@LastName nvarchar(50) = NULL,
	@Suffix nvarchar(10) = NULL,
	@EmailAddress nvarchar(50) = NULL
--WITH EXECUTE AS 'webSearch'
AS BEGIN
	SET NOCOUNT ON

	IF COALESCE(@FirstName, @MiddleName, @LastName, 
			@Suffix, @EmailAddress) IS NULL BEGIN
		RAISERROR ('Vous devez saisir au moins un critère de recherche', 16, 10)
		RETURN -1
	END

	DECLARE @sql varchar(8000)

	SET @sql = '
		SELECT FirstName, MiddleName, LastName, Suffix, EmailAddress
		FROM Person.Contact
		WHERE '
	IF @FirstName IS NOT NULL
		SET @sql = @sql + ' FirstName = ''' + @FirstName + ''' AND '
	IF @MiddleName IS NOT NULL
		SET @sql = @sql + ' MiddleName = ''' + @MiddleName + ''' AND '
	IF @LastName IS NOT NULL
		SET @sql = @sql + ' LastName = ''' + @LastName + ''' AND '
	IF @Suffix IS NOT NULL
		SET @sql = @sql + ' Suffix = ''' + @Suffix + ''' AND '
	IF @EmailAddress IS NOT NULL
		SET @sql = @sql + ' EmailAddress = ''' + @EmailAddress + ''' AND '

	SET @sql = LEFT(@sql, LEN(@sql)-3)
	PRINT @sql
	EXEC (@sql)
END
GO

EXEC Person.SearchContactsStatique @LastName = 'Adams'
GO
EXEC Person.SearchContactsDynamique @LastName = 'Adams'
GO

EXEC Person.SearchContactsStatique @LastName = 'Adams', @MiddleName = 'S'
GO
EXEC Person.SearchContactsDynamique @LastName = 'Adams', @MiddleName = 'S'
GO