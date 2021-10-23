CREATE VIEW Person.SomeContacts
WITH SCHEMABINDING
AS
    SELECT ContactID, FirstName, LastName
    FROM Person.Contact
    WHERE LastName LIKE '%Ad%';
GO

CREATE UNIQUE CLUSTERED INDEX cix$Person_SomeContacts
ON Person.SomeContacts (ContactID);

CREATE NONCLUSTERED INDEX nix$Person_SomeContacts$LastName_FirstName
ON Person.SomeContacts (LastName, FirstName);
GO

SELECT FirstName, LastName
FROM Person.Contact
WHERE LastName LIKE '%Ad%';
GO


