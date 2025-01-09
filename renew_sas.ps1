Param(

  [string]$environment,

  [string]$resource_group_name,
  [string]$storage_account_name,
  [string]$container_name,
  [string]$blob_name,

  [string]$key_vault_name,
  [string]$secret_name,

  [string]$permissions, #might need to change type
  [int]$expiry_days,
  [int]$remaining_days,

  [bool]$bypass_akv_network,
  [string]$umi_client_id = ""

)

# Functions
function checkExpiry([datetime]$expiry) {
  # Get difference between expiry current date and expiry date
  $time_dif = (($expiry) - (Get-Date))

  # If token needs renewed...
  if ($time_dif.Days -le $remaining_days) {
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
    $permissions,
    $expiry_date,
    $start_date
  )
  try {
    
    #Write-Output "Generating Token in SA $storage_account_name"
    Enable-AzureRmAlias
	  $context = $(Get-AzStorageAccount -ResourceGroupName $resource_group_name -Name $storage_account_name).Context
    $storage_context = New-AzureStorageContext -ConnectionString $($context.ConnectionString)

    if ($containerName -and $blobName) {
      try {
        # Generate SAS token (blob name)
        $sas_token = New-AzureStorageBlobSASToken -Container $containerName -Blob $blobName -Permission $permissions -StartTime $start_date -ExpiryTime $expiry_date -Context $storage_context
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
        # Generate SAS token (container name)
        $sas_token = New-AzureStorageContainerSASToken -Name $containerName -Permission $permissions -StartTime $start_date -ExpiryTime $expiry_date -Context $storage_context
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
        # Generate SAS token (storage account)
        $sas_token = New-AzureStorageAccountSASToken -Service Blob -ResourceType Service, Container, Object -Permission $permissions -StartTime $start_date -ExpiryTime $expiry_date -Context $storage_context
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
    $sasToken,
    $expiry_date,
    $start_date
  )
  try {
    $validity_period = [Timespan]($expiry_date - $start_Date)
    Write-Output "Validity period - $($validity_period)"
    Write-Output "Converting sas to secure string"
    $sas_secure = ConvertTo-SecureString $sasToken -AsPlainText -Force

    Write-Output "Adding sas to kv..."
    $secret = Set-AzKeyVaultSecret -VaultName $key_vault_name -Name $secret_name -SecretValue $sas_secure -Expires $expiry_date -NotBefore $start_date
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

  #Log in with MI
  Write-Output "Connecting with MI..."
  if($umi_client_id -ne ""){
    Write-Output "Using User-managed identity"
    Connect-AzAccount -Identity -accountId $umi_client_id
  } else {
    Connect-AzAccount -Identity
  }

  if($bypass_akv_network){
    $ip = Invoke-RestMethod -Uri api.ipify.org
    Write-Output "Bypass required, add rule for $ip/32 in $key_vault_name"
    Add-AzKeyVaultNetworkRule -IpAddressRange "$ip/32" -VaultName $key_vault_name
  }

  # Get secret
  Write-Output "Getting secret..."
  $secret = Get-AzKeyVaultSecret -VaultName $key_vault_name -Name $secret_name
  Write-Output "secret - $($secret | ConvertTo-Json)"
  $start_date = Get-Date
  $expiry_date = $start_date.AddDays($expiry_days)

  # Check if secret exists
  if ($secret -and $secret.Expires) {
    # Check expiry of secret
    if (checkExpiry($secret.Expires)) {
      # Create new token
      Write-Output "Secret needs renewed. Creating new token"
      $sas = generateSAS -saName $storage_account_name -containerName $container_name -blobName $blob_name -permissions $permissions -resourceGroupName $resource_group_name -start_date $start_date -expiry_date $expiry_date
      # Add token to kv
      addSecretToKV -sasToken $sas -expiry_date $expiry_date -start_date $start_date

    }
    else {
      Write-Output "Secret does not need renewed."
    }
  }
  else {
    Write-Output "Secret does not exist. Creating secret."
    # Create token
    $sas = generateSAS -saName $storage_account_name -containerName $container_name -blobName $blob_name -permissions $permissions -resourceGroupName $resource_group_name -start_date $start_date -expiry_date $expiry_date
    # Add token to kv
    addSecretToKV -sasToken $sas -expiry_date $expiry_date -start_date $start_date
  }
}
catch {
  Write-Error "Failed to process. Aborting.";
  Write-Error "Error: $($_)";
  exit
}

if($bypass_akv_network){
  Write-Output "Removing rule for $ip/32 in $key_vault_name"
  Remove-AzKeyVaultNetworkRule -IpAddressRange "$ip/32" -VaultName $key_vault_name
}