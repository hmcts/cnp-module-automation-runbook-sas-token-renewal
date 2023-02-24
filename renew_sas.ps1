Param(

  [string]$environment,

  [string]$resource_group_name,
  [string]$storage_account_name,
  [string]$container_name,
  [string]$blob_name,

  [string]$key_vault_name,
  [string]$secret_name,

  [string]$permissions, #might need to change type
  [datetime]$start_date,
  [datetime]$expiry_date,

  [bool]$bypassAKVNetwork = $false,
  [string]$accountId = ""

)


# Functions
function checkExpiry([datetime]$expiry) {
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
    
    #Write-Output "Generating Token in SA $storage_account_name"
    Enable-AzureRmAlias
	$context = $(Get-AzStorageAccount -ResourceGroupName $resource_group_name -Name $storage_account_name).Context
    $storage_context = New-AzureStorageContext -ConnectionString $($context.ConnectionString)

    if ($containerName -and $blobName) {
      try {
        #Write-Output "Generating Blob Token for $blobName in Container $containerName in SA $storage_account_name"
        # Generate SAS token (blob name)
        $sas_token = New-AzureStorageBlobSASToken -Container $containerName -Blob $blobName -Permission $permissions -StartTime $start_Date -ExpiryTime $expiry_date -Context $storage_context
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
        #Write-Output "Generating Container Token for $containerName in SA $storage_account_name"
        # Generate SAS token (container name)
        $sas_token = New-AzureStorageContainerSASToken -Name $containerName -Permission $permissions -StartTime $start_Date -ExpiryTime $expiry_date -Context $storage_context
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
        #Write-Output "Generating Storage Account Token for $storage_account_name"
        # Generate SAS token (storage account)
        $sas_token = New-AzureStorageAccountSASToken -Service Blob -ResourceType Service, Container, Object -Permission $permissions -StartTime $start_Date -ExpiryTime $expiry_date -Context $storage_context
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
    Disable-AzureRmAlias
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
    $sas_secure = ConvertTo-SecureString $sasToken -AsPlainText -Force
    Write-OutPut "Tagging"
    $tags = @{
        expiry = $expiry_date
    }
    Write-OutPut "Tags - $($tags | ConvertTo-Json)"
    Write-Output "Adding sas to kv..."
    $secret = Set-AzKeyVaultSecret -VaultName $key_vault_name -Name $secret_name -SecretValue $sas_secure -Tag $tags
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
  if($accountId -ne ""){
    Write-Host "Using User-managed identity"
    Connect-AzAccount -Identity -accountId $accountId
  } else {
    Connect-AzAccount -Identity
  }

  if($bypassAKVNetwork){
    $ip = Invoke-RestMethod -Uri api.ipify.org
    Add-AzKeyVaultNetworkRule -IpAddressRange $ip -VaultName $key_vault_name
  }

  # Get secret
  Write-Output "Getting secret..."
  $secret = Get-AzKeyVaultSecret -VaultName $key_vault_name -Name $secret_name
  Write-Output "secret - $($secret | ConvertTo-Json)"

  # Check if secret exists
  if ($secret -and $secret.Tags.Keys -contains "expiry") {
    # Check expiry of secret
    if (checkExpiry($secret.Tags["expiry"])) {
      # Create new token
      Write-Output "Secret needs renewed. Creating new token"
      $sas = generateSAS -saName $storage_account_name -containerName $container_name -blobName $blob_name -permissions $permissions -resourceGroupName $resource_group_name
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
    $sas = generateSAS -saName $storage_account_name -containerName $container_name -blobName $blob_name -permissions $permissions -resourceGroupName $resource_group_name
    # Add token to kv
    addSecretToKV -sasToken $sas
  }
}
catch {
  Write-Error "Failed to process. Aborting.";
  Write-Error "Error: $($_)";
  exit
}

if($bypassAKVNetwork){
  Remove-AzKeyVaultNetworkRule -IpAddressRange $ip -VaultName $key_vault_name
}