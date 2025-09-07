CREATE TABLE watermark
(
last_load Varchar(2000)
)

SELECT * FROM watermark

SELECT MIN(Date_ID) FROM source_cars_data


INSERT INTO watermark
VALUES('DT00000')


CREATE PROCEDURE Updatewatermark
@lastload Varchar(200)
AS
BEGIN 
  --Start transaction
  BEGIN TRANSACTION

  --Update incremental column in the table
  UPDATE watermark SET last_load=@lastload

END;

SELECT MAX(DATE_ID) FROM [dbo].[source_cars_data]