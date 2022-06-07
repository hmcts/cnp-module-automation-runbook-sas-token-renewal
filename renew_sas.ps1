Param(

  [string]$environment,

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
  if ($time_dif.Days -le 5) {
    return $true
  }
  else {
    return $false
  }

}

Function generateSAS() {

  param (
    $saName,
    $containerName,
    $blobName,
    $permissions
  )
  try {
    Write-Output "Generating Token in SA $storage_account_name"
    $storage_context = New-AzStorageContext -StorageAccountName $storage_account_name

    if ($containerName -and $blobName) {
      try {
        Write-Output "Generating Blob Token for $blobName in Container $containerName in SA $storage_account_name"
        # Generate SAS token (blob name)
        $sas_token = New-AzStorageBlobSASToken -Container $containerName -Blob $blobName -Permission $permissions -StartTime $start_Date -ExpiryTime $expiry_date -Context $storage_context
        return $sas_token
      }
      catch {
        Write-Error "Failed Generate Blob token. Aborting.";
        Write-Error "Error: $($_)";
        exit
      }
    
    }
    elseif ($containerName) {
      try {
        Write-Output "Generating Container Token for $containerName in SA $storage_account_name"
        # Generate SAS token (container name)
        $sas_token = New-AzStorageContainerSASToken -Name $containerName -Permission $permissions -StartTime $start_Date -ExpiryTime $expiry_date -Context $storage_context
        return $sas_token
      }
      catch {
        Write-Error "Failed Generate Container token. Aborting.";
        Write-Error "Error: $($_)";
        exit
      }
    }
    else {
      try {
        Write-Output "Generating Storage Account Token for $storage_account_name"
        # Generate SAS token (storage account)
        $sas_token = New-AzStorageAccountSASToken -Service Blob -ResourceType Service, Container, Object -Permission $permissions -StartTime $start_Date -ExpiryTime $expiry_date -Context $storage_context
        return $sas_token
      }
      catch {
        Write-Error "Failed Generate Storage Account token. Aborting.";
        Write-Error "Error: $($_)";
        exit
      }
    }
  }
  catch {
    Write-Error "Failed Generate Token. Aborting.";
    Write-Error "Error: $($_)";
    exit
  }

}

Function addSecretToKV() {

  param (
    $sasToken
  )
  try {
    $validity_period = [Timespan]($expiry_date - $start_Date)
    Write-Output "Validity period - $($validity_period)"
    Write-Output "Converting sas to secure string"
    $sas_secure = ConvertTo-SecureString [String]$sasToken -AsPlainText -Force
    Write-Output "Adding sas to kv..."
    $secret = Set-AzKeyVaultSecret -VaultName $key_vault_name -Name $secret_name -SecretValue $sas_secure
    Write-Output "Secret - $($secret | ConvertTo-Json)"
    Write-OutPut "Secret added to kv!"
  }
  catch {
    Write-Error "Failed Set Secrect. Aborting.";
    Write-Error "Error: $($_)";
    exit
  }
  
}

##########################################################

try {
	
  # Log in with MI
  Write-Output "Connecting with MI..."
  Connect-AzAccount -Identity
	
	
  # Get secret
  Write-Output "Getting secret..."
  $secret = Get-AzKeyVaultSecret -VaultName $key_vault_name -Name $secret_name
  Write-Output "secret - $($secret | ConvertTo-Json)"

  # Check if secret exists
  if ($secret) {
    # Check expiry of secret
    if (checkExpiry($secret.expires)) {
      # Create new token
      Write-Output "Secret needs renewed. Creating new token"
      $sas = generateSAS -saName $storage_account_name -containerName $container_name -blobName $blob_name -permissions $permissions
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
    $sas = generateSAS -saName $storage_account_name -containerName $container_name -blobName $blob_name -permissions $permissions
    # Add token to kv
    addSecretToKV -sasToken $sas
  }
}
catch {
  Write-Error "Failed to process. Aborting.";
  Write-Error "Error: $($_)";
  exit
}

