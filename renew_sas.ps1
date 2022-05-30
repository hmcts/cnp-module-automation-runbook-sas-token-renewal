Param(

  [string]$environment,
  [string]$product,

  [string]$storage_account_name,
  [string]$container_name,
  [string]$blob_name,

  [string]$key_vault_name,
  [string]$secret_name,

  [string]$permissions, #might need to change type
  [datetime]$start_date,
  [datetime]$expiry_date

)

# Functions
function checkExpiry($expiry) {
	# Get difference between expiry current date and expiry date
	$time_dif = (($expiry) - (Get-Date))

	# If token needs renewed...
	if ($time_dif.Days -le 5)
	{
		return $true
	}
	else 
	{
		return $false
	}

}

Function generateSAS() {

	param (
		$saName,
		$containerName,
		$blobName
	)

	if ($containerName -and $blobName) {
		# Generate SAS token (blob name)
		$storage_context = New-AzStorageContext -StorageAccountName $storage_account_name
		$sas_token = New-AzStorageBlobSASToken -Container $containerName -Blob $blobName -Permission "rl" -StartTime $start_Date -ExpiryTime $expiry_date -Context $storage_context
		return $sas_token
	}
	elseif($containerName) {
		# Generate SAS token (container name)
		$storage_context = New-AzStorageContext -StorageAccountName $storage_account_name
		$sas_token = New-AzStorageContainerSASToken -Name $containerName -Permission "rl" -StartTime $start_Date -ExpiryTime $expiry_date -Context $storage_context
		return $sas_token
	}
	else {
		# Generate SAS token (storage account)
		$storage_context = New-AzStorageContext -StorageAccountName $storage_account_name
		$sas_token = New-AzStorageAccountSASToken -Service Blob -ResourceType Service,Container,Object -Permission "rl" -StartTime $start_Date -ExpiryTime $expiry_date -Context $storage_context
		return $sas_token
	}
}

Function addSecretToKV() {

	param (
		$sasToken
	)

	$validity_period = [Timespan]($expiry_date - $start_Date)
	Write-Output "Validity period - $($validity_period)"
	Write-Output "Converting sas token to secure string"
	$sas_token = ConvertTo-SecureString "$sasToken" -AsPlainText -Force
	Write-Output "Adding sas to kv..."
	$secret = Set-AzKeyVaultSecret -VaultName $key_vault_name -Name $secret_name -SecretValue $secretvalue
	Write-Output "Secret - $($secret)"
	Write-OutPut "Secret added to kv!"
}

##########################################################

try {
	
	# Log in with MI
	Write-Output "Connecting with MI..."
	Connect-AzAccount -Identity
	
	
	# Get secret
	Write-Output "Getting secret..."
	$secret = Get-AzKeyVaultSecret -VaultName $key_vault_name -Name $secret_name
	Write-Output "secret - $($secret)"

	# Check if secret exists
	if ($secret){
		# Check expiry of secret
		if (checkExpiry($secret.expires)){
			# Create new token
			Write-Output "Secret needs renewed. Creating new token"
			generateSAS -saName $storage_account_name -containerName $container_name -blobName $blob_name
			# Add token to kv
			addSecretToKV -sasToken $sas

		}
		else {
			Write-Output "Secret does not need renewed."
		}
	}
	else {
		Write-Output "Secret does not exist. Creating secret."
		# Create token
		$sas = generateSAS -saName $storage_account_name -containerName $container_name -blobName $blob_name
		# Add token to kv
		addSecretToKV -sasToken $sas
	}
}
catch {
	Write-Error "Failed to process. Aborting.";
	Write-Error "Error: $($_)";
	exit
}

