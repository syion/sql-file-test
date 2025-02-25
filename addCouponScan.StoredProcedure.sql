USE [ELEAVE]
GO
/****** Object:  StoredProcedure [dbo].[addCouponScan]    Script Date: 28/12/2023 4:24:25 pm ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:     	Sayne Deniega
-- Create date: 
-- Description: 
-- =============================================
-- exec [addCouponScan] 'KMC1506', '1.00', 'TC0001'
CREATE PROCEDURE [dbo].[addCouponScan]
	@userid VARCHAR(20),
	@numcoupon VARCHAR(10),
	@createdby VARCHAR(20)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @username VARCHAR(80);
	DECLARE @coupon_count DECIMAL(10,2) = 0.00;
	DECLARE @active BIT = 1;
	DECLARE @coupon_amount DECIMAL(10,2) = 0.00;
	DECLARE @eod_generated BIT = 0;
	DECLARE @msg VARCHAR(150);

	SELECT @eod_generated = CASE WHEN REFERENCENO IS NOT NULL THEN 1 ELSE 0 END FROM COUPONREPORT WHERE CONVERT(DATE, REPORTDATE) = CONVERT(DATE, GETDATE())

	SELECT @username = u.USERID + ' - ' + u.USERNAME
		, @coupon_count = COALESCE(COUPONBALANCE, 0.00)
		, @active = k.is_active
	FROM LEAVEUSER u
	JOin KapsUser k on u.USERID = k.eleave_login_id
	LEFT JOIN COUPONUSERS c on c.USERID = u.USERID
	WHERE u.USERID = @userid;

	IF (@active = 0)
	BEGIN
		SET @msg = @username + ' is inactive.';
		RAISERROR (@msg, 16, 1);
	END
	ELSE 
	BEGIN
		SELECT TOP 1 @coupon_amount = PRICE FROM COUPONDETAIL WHERE ISDELETED = 0

		IF (CAST(@numcoupon AS DECIMAL(10, 2)) > @coupon_count)
		BEGIN
			SET @msg = @username + ' does not have enough coupons. Coupon balance is ' + CONVERT(VARCHAR, @coupon_count) + ' coupons.';
			RAISERROR (@msg, 16, 1);
		END
		ELSE
		BEGIN
			INSERT INTO COUPONSCAN (
				[USERID]
				,[NOOFCOUPON]
				,[AMOUNTCOUPON]
				,[TOTALAMOUNT]
				,[SCANNEDDATE]
				,[ISDELETED]
				,[CREATEDBY]
				,[CREATEDDATE]
				,[MODIFIEDBY]
				,[MODIFIEDDATE])
			SELECT @userid
				, CAST(@numcoupon AS DECIMAL(10, 2))
				, @coupon_amount
				, CAST(@numcoupon AS DECIMAL(10, 2)) * @coupon_amount
				, CASE WHEN @eod_generated = 1 THEN DATEADD(dd, 1, CONVERT(DATE, GETDATE())) ELSE CONVERT(DATE, GETDATE()) END
				, 0
				, @createdby
				, GETDATE()
				, @createdby
				, GETDATE()

			UPDATE COUPONUSERS
				SET COUPONTAKEN = COUPONTAKEN + @numcoupon,
					COUPONBALANCE = COUPONBALANCE - @numcoupon
			WHERE USERID = @userid
		END
	END
END
GO
