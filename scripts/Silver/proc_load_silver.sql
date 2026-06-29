/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

create or alter procedure silver.load_silver AS
BEGIN
	DECLARE @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		Print '======================================';
		Print 'Loading Silver Layer';
		Print '======================================';

		PRINT '---------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '---------------------------------------';

		-- ===============================================================================
		-- Loading silver.crm_cust_info
		-- ===============================================================================
		SET @start_time = GETDATE();
		PRINT '>> Truncate table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting Data Into: silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname, 
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)
		select 
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname) as cst_lastname,
		CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' Then 'Single'
			 WHEN UPPER(TRIM(cst_marital_status)) = 'M' then 'Married'
			 ELSE 'n/a'
		END cst_material_status,
		CASE WHEN UPPER(TRIM(cst_gndr)) = 'f' Then 'Female'
			 WHEN UPPER(TRIM(cst_gndr)) = 'M' then 'Male'
			 ELSE 'n/a'
		END cst_gndr,
		cst_create_date
		from (
			select 
			*, 
			ROW_NUMBER() over (partition by cst_id order by cst_create_date desc) as flag_last 
			from bronze.crm_cust_info
			WHERE cst_id is not null
		) t 
		WHERE flag_last = 1
 		SET @end_time = GETDATE();
		print '>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
		PRINT '---------------------------------------';

		-- ===============================================================================
		-- Loading silver.crm_prd_info
		-- ===============================================================================
		SET @start_time = GETDATE();
		PRINT '>> Truncate table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data Into: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info(
		prd_id
		,cat_id
		,prd_key
		,prd_nm
		,prd_cost 
		,prd_line
		,prd_start_dt
		,prd_end_dt
		)
		select 
		prd_id,
		replace(SUBSTRING(prd_key, 1, 5), '-', '_') as cat_id,
		substring(prd_key, 7, len(prd_key)) as prd_key,
		prd_nm, 
		isnull(prd_cost,0) as prd_cost,
		CASE UPPER(TRIM(prd_line))
			 WHEN 'M' then 'Mountain'
			 WHEN 'R' then 'Road'
			 WHEN 'S' then 'Other Sales'
			 WHEN 'T' then 'Touring'
			 ELSE 'n/a'
		END as prd_line,
		cast(prd_start_dt as date) as prd_start_dt,
		cast(LEAD(prd_start_dt) over (partition by prd_key order by prd_start_dt) -1 as date) as prd_end_dt
		from bronze.crm_prd_info
		 	SET @end_time = GETDATE();
			print '>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
			PRINT '---------------------------------------'
		
		-- ===============================================================================
		-- Loading silver.crm_sales_details
		-- ===============================================================================
		SET @start_time = GETDATE();
		PRINT '>> Truncate table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Inserting Data Into: silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details(
		sls_ord_num, 
		sls_prd_key,
		sls_cust_id, 
		sls_order_dt,
		sls_ship_dt, 
		sls_due_dt,	
		sls_sales,	
		sls_quantity,
		sls_price
		)
		select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		case when sls_order_dt = 0 or len(sls_order_dt) != 8 then null 
			 else CAST(CAST(sls_order_dt as varchar) AS DATE)
		end sls_order_dt,
		case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null 
			 else CAST(CAST(sls_ship_dt as varchar) AS DATE)
		end sls_ship_dt,
		case when sls_due_dt = 0 or len(sls_due_dt) != 8 then null 
			 else CAST(CAST(sls_due_dt as varchar) AS DATE)
		end sls_due_dt,
		case when sls_sales is null or sls_sales <=0 or sls_sales != sls_quantity * abs(sls_price)
			 then sls_quantity * abs(sls_price)
			 else sls_sales
		end as sls_sales,
		sls_quantity,
		case when sls_price is null or sls_sales <=0
			 then sls_sales / nullif(sls_quantity, 0)
			 else sls_price 
		end sls_price
		from bronze.crm_sales_details
		 	SET @end_time = GETDATE();
			print '>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
			PRINT '---------------------------------------'


		PRINT '---------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '---------------------------------------';		

		-- ===============================================================================
		-- Loading silver.erp_cust_az12
		-- ===============================================================================
		SET @start_time = GETDATE();
		PRINT '>> Truncate table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>> Inserting Data Into: silver.erp_cust_az12';
		insert into silver.erp_cust_az12(
		cid, 
		bdate,
		gen
		)
		select 
		CASE WHEN cid like 'NAS%' THEN SUBSTRING(cid, 4, len(cid))
			 ELSE cid
		end as cid, 
		case when bdate > GETDATE() then null 
			else bdate
		end as bdate,
		case when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
			 when upper(trim(gen)) in ('M', 'MALE') then 'Male'
			 else 'n/a'
		end as gen
		from bronze.erp_cust_az12

		-- ===============================================================================
		-- Loading silver.erp_loc_a101
		-- ===============================================================================
		SET @start_time = GETDATE();
		PRINT '>> Truncate table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Data Into: silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101(
		cid,
		cntry
		)
		select 
		replace(cid, '-', ''),
		case when trim(cntry) = 'DE' then 'Germany'
			 when trim(cntry) in ('US', 'USA') then 'United States'
			 when trim(cntry) = '' or cntry is null then 'n/a'
			 else trim(cntry) 
		end as cntry 
		from bronze.erp_loc_a101;
		 	SET @end_time = GETDATE();
			print '>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
			PRINT '---------------------------------------'
		
		-- ===============================================================================
		--Loading silver.erp_px_cat_g1v2
		-- ===============================================================================
		SET @start_time = GETDATE();
		PRINT '>> Truncate table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2(
		id,
		cat,
		subcat,
		maintenance
		)
		SELECT id,
			   cat,
			   subcat,
			   maintenance
		FROM bronze.erp_px_cat_g1v2
		 	SET @end_time = GETDATE();
			print '>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
			PRINT '---------------------------------------';

			SET @batch_end_time = GETDATE();
			print '===============================================';
			print 'Loading Silver Layer is Completed'
			print '		- Total Load Duration: ' + cast(datediff(second, @batch_start_time, @batch_end_time) as nvarchar) + ' seconds';
			print '===============================================';

	END TRY
	BEGIN CATCH
		print '=======================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR STATE' + CAST(ERROR_STATE() AS NVARCHAR);
		print '=======================================';
	END CATCH
END
