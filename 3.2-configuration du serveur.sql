-- pour v�rifier le type de v�rification de page�:
SELECT name, page_verify_option_desc FROM sys.databases;
-- pour d�sactiver la v�rification par CHECKSUM�:
ALTER DATABASE [AdventureWorks] SET PAGE_VERIFY NONE;
-- pour remplacer par une v�rification par TORN PAGE DETECTION�:
ALTER DATABASE [AdventureWorks] SET PAGE_VERIFY TORN_PAGE_DETECTION;
