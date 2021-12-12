USE [dbRecovery]
GO
/****** Object:  UserDefinedFunction [dbo].[Money_Transfer_Rate]    Script Date: 11/9/2021 2:15:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[Money_Transfer_Rate]
(@sar_amount float, @usd_rate float, @sar_rate float, @conv_sar_to_usd float)
returns @stats table (Is_Better varchar(5), Amount varchar(30), USD_Rate varchar(30), SAR_Rate varchar(30), Differnces varchar(50), Differnces_Desc nvarchar(300))
as
begin
declare @sar_result float, @usd_result float

select @usd_result = (@sar_amount / @conv_sar_to_usd) * @usd_rate
select @sar_result = @sar_amount * @sar_rate

if @usd_result > @sar_result 
begin
insert into @stats values ('USD', master.dbo.format(round(@sar_amount,2),-1)+' SAR',  master.dbo.format(round(@usd_result,2),2)+' EGP', master.dbo.format(round(@sar_result,2),2)+' EGP', master.dbo.format(@usd_result-@sar_result,2)+' EGP',dbo.[Tafkeet](@usd_result-@sar_result, 'EGP'))
end 
else if @sar_result > @usd_result 
begin
insert into @stats values ('SAR', master.dbo.format(round(@sar_amount,2),-1)+' SAR', master.dbo.format(round(@usd_result,2),2)+' EGP', master.dbo.format(round(@sar_result,2),2)+' EGP', master.dbo.format(@sar_result-@usd_result,2)+' EGP',dbo.[Tafkeet](@sar_result-@usd_result, 'EGP'))
end 
else if @sar_result = @usd_result 
begin
insert into @stats values ('=', master.dbo.format(round(@sar_amount,2),-1)+' SAR', master.dbo.format(round(@usd_result,2),2)+' EGP', master.dbo.format(round(@sar_result,2),2)+' EGP', master.dbo.format(0,2)+' EGP',dbo.[Tafkeet](0, 'EGP'))
end 

return
end

