CREATE TABLE watermark
(
last_load Varchar(2000)
)

SELECT * FROM watermark

SELECT MIN(Date_ID) FROM source_cars_data


INSERT INTO watermark
VALUES('DT00000')


IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Updatewatermark')
BEGIN
    DROP PROCEDURE Updatewatermark;
END
GO

CREATE PROCEDURE Updatewatermark
    @lastload Varchar(200)
AS
BEGIN
    --Start transaction
    BEGIN TRANSACTION

    --Update incremental column in the table
    UPDATE watermark SET last_load=@lastload

    COMMIT TRANSACTION
END;



SELECT MAX(DATE_ID) FROM [dbo].[source_cars_data]
