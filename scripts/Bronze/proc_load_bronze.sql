/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
	DECLARE @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime;
	BEGIN TRY	
		SET @batch_start_time = GETDATE();
		Print '======================================';
		Print 'Loading Bronze Layer';
		Print '======================================';

		PRINT '---------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '---------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.crm_cust_info'
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT '>> Inserting Data Into: bronze.crm_cust_info'
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\Momotaro\OneDrive\Desktop\Data Project DWH\cust_info.csv'
		WITH (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @start_time = GETDATE();
		print '>> Load Duration: ' + cast(DATEDIFF(second, @start_time, @end_time) as nvarchar) + ' seconds';
		PRINT '---------------------------------------';

		SET @start_time = getdate(); 
		PRINT '>> Truncating table: bronze.crm_prd_info'
		TRUNCATE TABLE bronze.crm_prd_info;
		PRINT '>> Inserting Data Into: bronze.crm_prd_info'
		BULK INSERT bronze.crm_prd_info
		from 'C:\Users\Momotaro\OneDrive\Desktop\Data Project DWH\prd_info.csv'
		with (
			FIRSTROW = 2, 
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		print '>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
		PRINT '---------------------------------------';


		SET @start_time = getdate();
		PRINT '>> Truncating table: bronze.crm_sales_details'
		TRUNCATE TABLE bronze.crm_sales_details; 
		PRINT '>> Inserting Data Into: bronze.crm_sales_details'
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\Momotaro\OneDrive\Desktop\Data Project DWH\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			Fieldterminator = ',',
			TABLOCK
		);
		set @end_time = getdate(); 
		print '>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
		PRINT '---------------------------------------';
		

		PRINT '---------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '---------------------------------------';

		SET @start_time = GETDATE(); 
		PRINT '>> Truncating table: bronze.erp_cust_az12'
		TRUNCATE TABLE bronze.erp_cust_az12;
		PRINT '>> Inserting Data Into: bronze.erp_cust_az12'
		BULK INSERT bronze.erp_cust_az12
		from 'C:\Users\Momotaro\OneDrive\Desktop\Data Project DWH\cust_az12.csv'
		WITH ( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE(); 
		PRINT '>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
		PRINT '---------------------------------------';

		set @start_time = GETDATE();
		PRINT '>> Truncating table: bronze.erp_loc_a101'
		TRUNCATE TABLE bronze.erp_loc_a101; 
		PRINT '>> Inserting Data Into: bronze.erp_loc_a101'
		BULK INSERT bronze.erp_loc_a101 
		FROM 'C:\Users\Momotaro\OneDrive\Desktop\Data Project DWH\loc_a101.csv'
		WITH( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		set @end_time = GETDATE(); 
		print '>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds';
		PRINT '---------------------------------------';


		SET @start_time = getdate(); 
		PRINT '>> Truncating table: bronze.erp_px_cat_g1v2'
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\Momotaro\OneDrive\Desktop\Data Project DWH\px_cat_g1v2.csv'
		WITH ( 
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		set @end_time = getdate();
		print '>> Load duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + ' seconds'; 
		PRINT '---------------------------------------';

		SET @batch_end_time = GETDATE();
		print '===============================================';
		print 'Loading Bronze Layer is Completed'
		print '		- Total Load Duration: ' + cast(datediff(second, @batch_start_time, @batch_end_time) as nvarchar) + ' seconds';
		print '===============================================';

	END TRY
	BEGIN CATCH
		print '=======================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'ERROR MESSAGE' + ERROR_MESSAGE();
		PRINT 'ERROR NUMBER' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR STATE' + CAST(ERROR_STATE() AS NVARCHAR);
		print '=======================================';
	END CATCH
END
