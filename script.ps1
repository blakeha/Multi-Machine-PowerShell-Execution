Param (
	$projectFile,
	$server
)

function Log($message)
{
	Write-Output "$("[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date))[$($server.hostname)] $($message)"
}
Log("$($server.hostname) has begun executing script.ps1")



# Your custom code here

Write-Progress -Activity "Your activity info" -Status "Status info like: 10% Complete!" -PercentComplete 100

Log("$($server.hostname) completed successfully.")

