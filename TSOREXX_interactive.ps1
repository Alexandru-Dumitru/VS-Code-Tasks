Import-Module './helper-functions' 

Write-Host "Running on remote system. Waiting for output..."

# Loading params from json file
$params = Get-Content '.\params.json' | ConvertFrom-JSON

# check if zosmf profile is passed from task, if not, take it from params
if  ($args[1]) {
    $zosmfProfile = $args[1]
} else {
    $zosmfProfile = $params.tsorexx.zosmfProfile
}

# check if tso profile is passed from task, if not, take it from params
if  ($args[2]) {
    $tsoProfile = $args[2]
} else {
    $tsoProfile = $params.tsorexx.tsoProfile
}

$rexxFile = Get-Remote_FilePath -localFilePath $args[0]
# Zowe CLI command to submit a local file and get back the spool files

# Start a TSO address space 
$addressSpaceKey = zowe tso start as --sko --zosmf-p $zosmfProfile --tso-p $tsoProfile

if ($null -ne $addressSpaceKey ) {
    # Send data to the TSO address space 
    # $output = zowe tso send as $addressSpaceKey --data "exec '$rexxFile'" --zosmf-p $zosmfProfile --rfj | ConvertFrom-JSON
    
    # TODO: this doesn't really makes sense
    # TODO: need to wrap each data send in output + error checking

    $tempOutput = zowe tso send as $addressSpaceKey --data "exec '$rexxFile'" --zosmf-p $zosmfProfile --rfj | ConvertFrom-JSON
    Write-Host $tempOutput.stdout
    # Reply to first PULL
    $tempOutput = zowe tso send as $addressSpaceKey --data "$($params.tsorexx.input1)" --zosmf-p $zosmfProfile --rfj | ConvertFrom-JSON
    Write-Host "Input: $($params.tsorexx.input1)"
    Write-Host $tempOutput.stdout
    
    # Reply to second PULL
    $tempOutput = zowe tso send as $addressSpaceKey --data "$($params.tsorexx.input2)" --zosmf-p $zosmfProfile --rfj | ConvertFrom-JSON
    Write-Host "Input: $($params.tsorexx.input2)"
    Write-Host $tempOutput.stdout
} else {
    throw "Opening TSO address space failed!"
}

# Stop the TSO address space 
# $addressSpaceKeyDone = zowe tso stop as $addressSpaceKey --zosmf-p $zosmfProfile
zowe tso stop as $addressSpaceKey --zosmf-p $zosmfProfile | Out-Null


# Basic error handling

# Zowe command error handling

# if ($null -ne $output -And $output.exitCode -ne 0) {
#     throw $($output.message)
# }

# REXX error handling
# TODO: this doesn't apply
$RCregex = '(RC\(-\d\))'
$RCcoderegex = '-\d'
$hasRCinOutput = [regex]::match($output.stdout,$RCregex).Groups[1].Success
$value = [regex]::match($output.stdout,$RCregex).Groups[1].Value
$RC = [regex]::match($value,$RCcoderegex).Value

if (-Not $hasRCinOutput) {
    Write-Host 
    Write-Host "OUTPUT:"
    Write-Host 
    Write-Host $output.stdout
    # Write-Host $output.data.zosmfResponse.tsoData
} else {
    Write-Host "REXX finished in error." 
    Write-Host "Return Code: $($RC)"
    Write-Host
    Write-Host "Full output follows:"
    Write-Host
    Write-Host $output.stdout
}