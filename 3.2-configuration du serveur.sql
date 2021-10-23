-- pour vérifier le type de vérification de page :
SELECT name, page_verify_option_desc FROM sys.databases;
-- pour désactiver la vérification par CHECKSUM :
ALTER DATABASE [AdventureWorks] SET PAGE_VERIFY NONE;
-- pour remplacer par une vérification par TORN PAGE DETECTION :
ALTER DATABASE [AdventureWorks] SET PAGE_VERIFY TORN_PAGE_DETECTION;
