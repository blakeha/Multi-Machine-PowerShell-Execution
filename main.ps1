$SCRIPT_VERSION = "1.0.0"
	Clear-Host
	Write-Output "Script Version: $($SCRIPT_VERSION)"
	
	function Log($message)
	{
		Write-Output "$("[{0:MM/dd/yy} {0:HH:mm:ss}][System]" -f (Get-Date)) $($message)"
	}
	
	
	# Get-NetFirewallRule -Name 'WINRM*' | Select-Object Name
	# Enable-PSRemoting -SkipNetworkProfileCheck -Force
	# Set-NetFirewallRule -Name 'WINRM-HTTP-In-TCP' -RemoteAddress Any
	
	
	$PROJECT_FILE = ($PSScriptRoot + "\settings.json");
	$ProjectFile = Get-Content -Path $PROJECT_FILE | ConvertFrom-Json
	$Root = $PSScriptRoot
	$jobs = [System.Collections.ArrayList]@();
	
	# loop machines in project file
	$ProjectFile.servers | ForEach-Object -Parallel {
        $PROJECT_FILE = $using:PROJECT_FILE
        $ProjectFile = $using:ProjectFile
        $Root = $using:Root

        function Log($message)
	{
		Write-Output "$("[{0:MM/dd/yy} {0:HH:mm:ss}][System]" -f (Get-Date)) $($message)"
	}

		# set machine has trusted
		#set-item wsman:\localhost\client\trustedhosts -Concatenate -value $_.hostname -Force -Confirm:$false
		
		# get credentials for remote access to server
		if ($_.credentials.password)
		{
			$securePassword = (ConvertTo-SecureString $_.credentials.password -AsPlainText -Force)
			$credentials = New-Object System.Management.Automation.PSCredential $_.credentials.username, $securePassword
		}
		else
		{
			$credentials = (Get-Credential -Message "Credentials for $($_.hostname)" -UserName $_.credentials.username)
		}
		
		try
		{
			$session = New-PSSession -ComputerName $_.hostname -Credential $credentials
		}
		catch
		{
			Log "There was an issue remoting into machine: $($_.hostname)";
			Log $_
		}
		
		try
		{
            Log "$($_.hostname) transferring bin file"
			# download package files
			Invoke-Command -Session $session -ScriptBlock {
				New-Item -Path 'C:\LS Retail\Multi-Machine_PowerShell\bin' -ItemType Directory -Force -Verbose:$false | Out-Null
			}
			
			Copy-Item -Path "$($Root)\bin\*" -Destination "C:\LS Retail\Multi-Machine_PowerShell\bin\" -ToSession $session | Out-Null
		}
		catch
		{
			Log "Error transfering bin file"
			Log $_
		}
		
		Invoke-Command -Session $session -FilePath "$($ProjectFile.script_path)" -ArgumentList $ProjectFile, $_ 
		
		#$j = Get-Job
		#$j | Format-List -Property *
		
		Log "$($_.hostname) connection and transfer complete."
	}
	
	Write-Output "`n`n Waiting for all jobs to complete. Please Hold"

	$res = $jobs | Wait-Job | Receive-Job
	$res | Out-File -FilePath ".\Logs.txt"
	$res

Get-PSSession | Disconnect-PSSession | Out-Null