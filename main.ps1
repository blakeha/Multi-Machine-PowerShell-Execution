$SCRIPT_VERSION = "1.0.0"
	Clear-Host
	Write-Output "Script Version: $($SCRIPT_VERSION)"
	
	function Log($message)
	{
		Write-Output "$("[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)) $($message)"
	}
	
	
	
	
	# Get-NetFirewallRule -Name 'WINRM*' | Select-Object Name
	# Enable-PSRemoting -SkipNetworkProfileCheck -Force
	# Set-NetFirewallRule -Name 'WINRM-HTTP-In-TCP' -RemoteAddress Any
	
	
	$PROJECT_FILE = ($PSScriptRoot + "\settings.json");
	$ProjectFile = Get-Content -Path $PROJECT_FILE | ConvertFrom-Json
	
	$jobs = [System.Collections.ArrayList]@();
	
	# loop machines in project file
	foreach ($server in $ProjectFile.servers)
	{
		
		Write-Output "`n`n#### $($server.hostname) ####`n"
		
		# set machine has trusted
		set-item wsman:\localhost\client\trustedhosts -Concatenate -value $server.hostname -Force -Confirm:$false
		
		# get credentials for remote access to server
		if ($server.credentials.password)
		{
			$securePassword = (ConvertTo-SecureString $server.credentials.password -AsPlainText -Force)
			$credentials = New-Object System.Management.Automation.PSCredential $server.credentials.username, $securePassword
		}
		else
		{
			$credentials = (Get-Credential -Message "Credentials for $($server.hostname)" -UserName $server.credentials.username)
		}
		
		try
		{
			$session = New-PSSession -ComputerName $server.hostname -Credential $credentials
			$session
		}
		catch
		{
			Log "There was an issue remoting into machine: $($server.hostname)";
			Log $_
		}
		
		try
		{
			# download package files
			Invoke-Command -Session $session -ScriptBlock {
				New-Item -Path 'C:\LS Retail\Multi-Machine_PowerShell\bin' -ItemType Directory -Force -Verbose:$false | Out-Null
			}
			
			Copy-Item -Path "$($PSScriptRoot)\bin\*" -Destination "C:\LS Retail\Multi-Machine_PowerShell\bin\" -ToSession $session
		}
		catch
		{
			Log "Error transfering bin file"
			Log $_
		}
		
		$jobs.Add((Invoke-Command -Session $session -FilePath "$($ProjectFile.script_path)" -AsJob -ArgumentList $ProjectFile, $server))
		
		#$j = Get-Job
		#$j | Format-List -Property *
		
		Write-Output "`n`n#### $($server.hostname) End ####"
	}
	
	Write-Output "`n`n Waiting for all jobs to complete. Please Hold"
	
	$res = $jobs | Wait-Job | Receive-Job
	$res | Out-File -FilePath ".\Logs.txt"
	$res