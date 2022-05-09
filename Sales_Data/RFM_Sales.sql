-- Analisis general de la base de datos
select * from sales_data_sample sds ;

-- Revisar los valores unicos de algunas variables
select distinct STATUS  from sales_data_sample sds;
select distinct YEAR_ID  from sales_data_sample sds;
select distinct PRODUCTLINE from sales_data_sample sds;
select distinct CITY  from sales_data_sample sds;
select distinct COUNTRY  from sales_data_sample sds;
select distinct DEALSIZE  from sales_data_sample sds;


-- En que mes es mayor las ventas de la empresa?
select MONTH_ID , sum(SALES) Revenue , count(ORDERNUMBER) NumSales
from sales_data_sample sds 
where YEAR_ID = 2003
group by MONTH_ID
order by 2 desc ;

--Noviembre se ve el mejor mes en cuestion de ventas, que productos se venten en noviembre 
select MONTH_ID ,PRODUCTLINE ,sum(SALES) Revenue , count(ORDERNUMBER) NumSales
from sales_data_sample sds 
where YEAR_ID = 2003 and MONTH_ID = 11
group by MONTH_ID ,PRODUCTLINE 
order by 2 desc ;
--Quien es el mejor cliente? (Analisis con RFM)
DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from sales_data_sample)) Recency
	from dbo.sales_data_sample
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm


---EXTRAs----
--Cual ciudad son las ventas mas altas 
select country, sales from
(
    select 
            COUNTRY,
            sales,
            dense_rank() OVER (partition by COUNTRY order by sales desc) as country_sales
    from [sales_data_sample]

)x
where x.country_sales = 1
ORDER BY sales desc;

-- Estados unidos el pais que mas se vende, cual es el producto que se vende mas 
select  PRODUCTLINE, sum(sales) Revenue
from [sales_data_sample]
where country = 'USA'
group by   PRODUCTLINE
order by 2 desc;
