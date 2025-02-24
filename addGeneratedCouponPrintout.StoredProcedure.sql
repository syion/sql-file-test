USE [ELEAVE]
GO
/****** Object:  StoredProcedure [dbo].[addGeneratedCouponPrintout]    Script Date: 28/12/2023 4:24:25 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:     	Sayne Deniega
-- Create date: 
-- Description: 
-- =============================================
-- exec [addGeneratedCouponPrintout] 6, 0, '01/01/2018', '01/07/2018', '3.50', 'FOOD & BEVERAGE ONLY', 'TC0001'
CREATE PROCEDURE [dbo].[addGeneratedCouponPrintout]
	@compid int,
	@compcode varchar(50),
	@deptid int,
	@deptcode varchar(50),
	@validfrom datetime,
	@validto datetime,
	@price varchar(20),
	@description varchar(50),
	@createdby varchar(20)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @id int = 0;
	DECLARE @count int;
	DECLARE @amount money;

	INSERT INTO COUPONPRINT (
		COUPONCOMPANYID
		, COUPONCOMPANYCODE
		, COUPONDEPARTMENTID
		, COUPONDEPARTMENTCODE
		, VALIDFROM
		, VALIDTO
		, PRICE
		, [DESCRIPTION]
		, CREATEDBY
		, CREATEDDATE
		, MODIFIEDBY
		, MODIFIEDDATE
	)
	SELECT @compid
		, @compcode
		, @deptid
		, @deptcode
		, @validfrom
		, @validto
		, @price
		, @description
		, @createdby
		, GETDATE()
		, @createdby
		, GETDATE()

	SET @id = @@IDENTITY
	
	IF (@id <> 0)
	BEGIN
		INSERT INTO COUPONPRINTDETAIL(
			COUPONPRINTID
			, COUPONUSERSID
			, USERID
			, NUMOFCOUPON
			, AMOUNT
			, CREATEDBY
			, CREATEDDATE
			, MODIFIEDBY
			, MODIFIEDDATE
		)
		SELECT @id
			, c.COUPONUSERSID
			, c.USERID
			, u.MEALCOUPONWEEKLYLIMIT
			, CONVERT(DECIMAL(10,2), u.MEALCOUPONWEEKLYLIMIT * CONVERT(MONEY, @price))
			, @createdby
			, GETDATE()
			, @createdby
			, GETDATE()
		FROM COUPONUSERS c
		JOIN LEAVEUSER u on c.USERID = u.USERID
		WHERE (c.COUPONCOMPID = @compid OR @compid = 0)
			AND (c.COUPONDEPTID = @deptid OR @deptid = 0)
			AND RESIGNEDDATE IS NULL
			AND COALESCE([ENABLED], 0) = 1
			AND COALESCE(HOLD, 0) = 0
	
		SELECT @count = SUM(NUMOFCOUPON), @amount = CONVERT(DECIMAL(10,2), SUM(AMOUNT)) FROM COUPONPRINTDETAIL WHERE COUPONPRINTID = @id;

		UPDATE COUPONPRINT
			SET TOTALCOUPON = @count, TOTALAMOUNT = @amount
		WHERE COUPONPRINTID = @id

		UPDATE u
			SET COUPONENTITLEMENT = COUPONENTITLEMENT + NUMOFCOUPON
				,COUPONBALANCE = COUPONBALANCE + NUMOFCOUPON
		FROM COUPONPRINTDETAIL d
		JOIN COUPONUSERS u on u.USERID = d.USERID
		WHERE d.COUPONPRINTID = @id
	END
END
GO
