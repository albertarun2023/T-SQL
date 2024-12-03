
--SSIS projects and packages
SELECT 
	po.[name]			AS	[ProjectName],
	pa.[name]			AS	[PackageName],
	po.[deployed_by_name]	AS	[DeployedBy],
	po.[last_deployed_time]	AS	[LastDeployedTime],
	po.[created_time]		AS	[created_time]
FROM		[SSISDB].[internal].[projects] po
LEFT JOIN	[SSISDB].[internal].[packages] pa ON po.[project_id] = pa.[project_id] 

--SSIS configuration and parameter values
SELECT TOP (1000) 
	   p.[parameter_id]
      ,p.[project_id]
      ,p.[project_version_lsn]
      ,p.[object_type]
      ,p.[object_name]
      ,p.[parameter_name]
      ,p.[parameter_data_type]
      ,p.[required]
      ,p.[sensitive]
      ,p.[description]
      ,p.[design_default_value]
      ,p.[default_value]
      ,p.[sensitive_default_value]
      ,p.[base_data_type]
      ,p.[value_type]
      ,p.[value_set]
      ,p.[referenced_variable_name]
      ,p.[validation_status]
      ,p.[last_validation_time]
  FROM [SSISDB].[internal].[object_parameters] AS p
  INNER JOIN 
				(
					SELECT 
						[project_id],
						MAX([project_version_lsn]) AS [Max_project_version_lsn] 
					FROM [SSISDB].[internal].[object_parameters]
					GROUP BY [project_id]
				)mp ON p.[project_id] = mp.[project_id] AND p.[project_version_lsn] = mp.[Max_project_version_lsn]
  
  ORDER BY 1 DESC

--Some additional queries to play with.
   
  select * from [internal].[environment_references]
  select * from [internal].[environment_variables]
  select * from [internal].[environments]


--Query 3 Errors and Warnings
SELECT TOP (1000)
	om.[operation_id],
	e.[folder_name],
	e.[project_name],
	e.[package_name],
	om.[message_source_type],
	om.[message],   
	om.[message_time] 
FROM		[SSISDB].[internal].[operation_messages]	om
INNER JOIN	[SSISDB].[internal].[executions]			e				ON om.[operation_id] = e.[execution_id] 
WHERE		om.[message_type] IN (110,120,130)--Warning,Error,TaskFailed
ORDER BY om.[operation_message_id] DESC
