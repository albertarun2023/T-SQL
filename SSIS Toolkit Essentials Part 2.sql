--Package analysis
SELECT TOP 1000
	o.[operation_id]								AS	[OperationId],
	o.[object_name]									AS	[ObjectName],
	e.[package_name]								AS	[PackageName],
	DATEDIFF(SECOND,o.[start_time],o.[end_time])	AS	[DurationInSeconds],
	CASE o.[operation_type]
			WHEN 1		THEN 'Integration Services initialization'						 
			WHEN 2		THEN 'Retention window'						 				 
			WHEN 3		THEN 'MaxProjectVersion'						 			 
			WHEN 101	THEN 'deploy_project'						 				 
			WHEN 102	THEN 'get_project'							 				 
			WHEN 106	THEN 'restore_project'						 			 
			WHEN 200	THEN 'create_execution and start_execution'	 
			WHEN 202	THEN 'stop_operation'						 				 
			WHEN 300	THEN 'validate_project'						 			 
			WHEN 301	THEN 'validate_package'						 			 
			WHEN 1000	THEN 'configure_catalog'						 
	ELSE NULL END									AS	[OperationType],
	o.[created_time]								AS	[CreatedTime],
	CASE [object_type] 
			WHEN 10	THEN 'folder'					 
			WHEN 20	THEN 'project'					 
			WHEN 30	THEN 'package'					  
			WHEN 40	THEN 'environment'				 
			WHEN 50	THEN 'instance of execution'	
	ELSE NULL END									AS	[ObjectType],
	CASE o.[status] 
			WHEN 1 THEN 'created'
			WHEN 2 THEN 'running'
			WHEN 3 THEN 'canceled'
			WHEN 4 THEN 'failed'
			WHEN 5 THEN 'pending'
			WHEN 6 THEN 'ended unexpectedly'
			WHEN 7 THEN 'succeeded'
			WHEN 8 THEN 'stopping'
			WHEN 9 THEN 'completed'
		ELSE NULL END								AS	[Status],
		o.[start_time]								AS	[StartTime],	
		o.[end_time]								AS	[EndTime],	 	 
		o.[caller_name]								AS	[CallerName],		 
		o.[stopped_by_name]							AS	[StoppedByName],	 
		o.[server_name]								AS	[ServerName],
		o.[machine_name]							AS	[MachineName]	
 FROM [SSISDB].[internal].[operations] o
 LEFT JOIN [SSISDB].[internal].[executions] e ON o.[operation_id] = e.[execution_id]
 ORDER BY 1 DESC

--Package task analysis
SELECT 
	omPackageBegin.[operation_id]			AS	[OperationId],
	e.[folder_name]							AS	[FolderName],
	e.[project_name]						AS	[ProjectName],
	e.[package_name]						AS	[PackageName],
	emPackageBegin.[message_source_name]	AS	[TaskName],
	CASE o.[status] 
					WHEN 1 THEN 'created'
					WHEN 2 THEN 'running'
					WHEN 3 THEN 'canceled'
					WHEN 4 THEN 'failed'
					WHEN 5 THEN 'pending'
					WHEN 6 THEN 'ended unexpectedly'
					WHEN 7 THEN 'succeeded'
					WHEN 8 THEN 'stopping'
					WHEN 9 THEN 'completed'
	ELSE NULL END							AS [PackageStatus],
	DATEDIFF(SECOND,omPackageBegin.[message_time],Finish.[message_time])					AS	[ElapsedTimeInSeconds],
	--DATEDIFF(SECOND,omPackageBegin.[message_time],ISNULL(Finish.[message_time], GETDATE())) AS	[ElapsedTimeInSecondsWithIsNullGetDate],
	omPackageBegin.[message_time]			AS	[PackageStartTime], 
	Finish.[message_time]					AS	[PackageEndTime], 
	omPackageBegin.[message]				AS	[StartMessage],	
	Finish.[message]						AS	[EndMessage] 
FROM [SSISDB].[internal].[event_messages]	AS		emPackageBegin
INNER JOIN [SSISDB].[internal].[executions]	AS		e				ON	emPackageBegin.operation_id				= e.execution_id -- Extract Project and Package Name
INNER JOIN [SSISDB].[internal].[operations]	AS		o				ON	emPackageBegin.operation_id				= o.operation_id -- Extract Status
INNER JOIN [SSISDB].[internal].[operation_messages] omPackageBegin	ON	omPackageBegin.operation_message_id		= emPackageBegin.event_message_id 																	
																		AND omPackageBegin.message_type			= 30 --30 is task/package 'started'
																		AND omPackageBegin.message_source_type	= 40 --package level, 40 is task level
LEFT JOIN  

			(
				SELECT
						emPackageEnd.[message_source_id],
						emPackageEnd.[operation_id],
						emPackageEnd.[package_name], 
						emPackageEnd.[message_source_name],
						omPackageEnd.[operation_message_id],
						omPackageEnd.[message_time], 
						omPackageEnd.[message]					
					FROM	
					 [SSISDB].[internal].[event_messages]				emPackageEnd
					INNER JOIN [SSISDB].[internal].[operation_messages] omPackageEnd	ON	omPackageEnd.[operation_message_id]	= emPackageEnd.[event_message_id] 																	
																		AND omPackageEnd.[message_type]							= 40 --30 is task/package 'ended'
																		AND omPackageEnd.[message_source_type]					= 40 --30 package level, 40 is task level
			) Finish
			ON emPackageBegin.[message_source_id] = Finish.[message_source_id] AND emPackageBegin.[operation_id] = Finish.[operation_id]
--where emPackageBegin.operation_id = 27
ORDER BY PackageStartTime DESC
