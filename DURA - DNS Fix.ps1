$servers = Get-Content -Path D:\Scripts\ServerDNS\FixServers.csv

##### Define Subnets #####
$AARsub = @("10.50.50.","10.160.47.","143.39.203.","155.128.141.")
$HEIsub = @("10.54.50.","192.168.110.","192.168.132.","192.168.113.")
$CNDGsub = @("10.71.50.","10.224.66.")
$CNNCsub = @("10.72.50.")
$BECTsub = @("10.32.50.","137.180.19","137.180.20")
$LGGAsub = @("10.24.50.","137.180.56.","143.18.180.")
$FBGAsub = @("10.41.50.")
$CVTNsub = @("10.16.50.","10.184.37.")
$CHILsub = @("10.39.50.")
$AZURENAsub = @("10.6.12.","10.6.100.","10.7.100.","10.223.137.","10.6.4","10.6.12.","10.82.2.","10.9.17.","10.6.50.","10.6.2.","10.223.128.","10.8.100.","10.82.100.")
$AZUREEUsub = @("")

##### Define DNS Servers #####
$AARdns = @("10.50.50.175","10.54.50.175","10.6.100.175")
$HEIdns = @("10.54.50.175","10.50.50.175","10.6.100.175")
$CNDGdns = @("10.71.50.175","10.72.50.175","10.80.2.5")
$CNNCdns = @("10.72.50.175","10.71.50.175","10.80.2.5")
$BECTdns = @("10.24.50.175","10.16.50.175","10.6.100.175")
$LGGAdns = @("10.24.50.175","10.16.50.175","10.6.100.175")
$FBGAdns = @("10.24.50.175","10.16.50.175","10.6.100.175")
$CVTNdns = @("10.16.50.175","10.24.50.175","10.6.100.175")
$CHILdns = @("10.24.50.175","10.16.50.175","10.6.100.175")
$AZURENAdns = @("10.6.100.175","10.16.50.175","10.24.50.175")
$AZUREEUdns = @("10.54.50.175","10.50.50.175","10.6.100.175")

foreach ( $server in $servers ) {
    write-host "Processing $server :"
    ##### Get Computer Information #####
    $Networks = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $server -Filter IPEnabled=TRUE
    foreach($Network in $Networks) {
        $DNSServers = $Network.DNSServerSearchOrder
        $IPAddr = $Network.IPAddress[0]
        $INTIndex = $Network.InterfaceIndex
        If(!$DNSServers) {
	        $PrimaryDNSServer = "Notset"
	        $SecondaryDNSServer = "Notset"
            $ThirdDNSServer = "Notset"
            write-host "- ERROR: No DNS Servers configured, Aborting..." -ForegroundColor Red
            write-host "-----"
            break
        } elseif($DNSServers.count -eq 1) {
	        $PrimaryDNSServer = $DNSServers[0]
	        $SecondaryDNSServer = "Notset"
            $ThirdDNSServer = "Notset"
        } elseif($DNSServers.count -eq 2) {
            $PrimaryDNSServer = $DNSServers[0]
	        $SecondaryDNSServer = $DNSServers[1]
            $ThirdDNSServer = "Notset"
        } else {
	        $PrimaryDNSServer = $DNSServers[0]
	        $SecondaryDNSServer = $DNSServers[1]
            $ThirdDNSServer = $DNSServers[2]
        }
        If($network.DHCPEnabled) {
	        $IsDHCPEnabled = $true
        } else {
            $IsDHCPEnabled = $false
        }

#        Write-Host "- Interface ID: $INTIndex"
#        Write-Host "- IP Address: $IPAddr"
#        Write-Host "- DHCP Enabled: $IsDHCPEnabled"
#        Write-Host "- DNS 1: $PrimaryDNSServer"
#        Write-Host "- DNS 2: $SecondaryDNSServer"
#        Write-Host "- DNS 3: $ThirdDNSServer"
         
        ##### Match Subnet to IP #####
        if($IPAddr -match ($AARsub -join '|')) { $Location = "AAR" }
        elseif($IPAddr -match ($HEIsub -join '|')) { $Location = "HEI" }
        elseif($IPAddr -match ($CNDGsub -join '|')) { $Location = "CNDG" }
        elseif($IPAddr -match ($CNNCsub -join '|')) { $Location = "CNNC" }
        elseif($IPAddr -match ($BECTsub -join '|')) { $Location = "BECT" }
        elseif($IPAddr -match ($LGGAsub -join '|')) { $Location = "LGGA" }
        elseif($IPAddr -match ($FBGAsub -join '|')) { $Location = "FBGA" }
        elseif($IPAddr -match ($CVTNsub -join '|')) { $Location = "CVTN" }
        elseif($IPAddr -match ($CHILsub -join '|')) { $Location = "CHIL" }
        elseif($IPAddr -match ($AZURENAsub -join '|')) { $Location = "AZURENA" }
        elseif($IPAddr -match ($AZUREEUsub -join '|')) { $Location = "AZUREEU" }
        else { 
            $Location = "UNKNOWN"
            Write-Host "- ERROR: Can not correlate location aborting..." -ForegroundColor red
            write-host "-----"
            break
        }

#        Write-Host "- Location: $Location"
        ##### Check if DNS servers are correct #####
        $PDNS = $((Get-Variable -Name "$($Location)dns").Value)[0]
        $SDNS = $((Get-Variable -Name "$($Location)dns").Value)[1]
        $TDNS = $((Get-Variable -Name "$($Location)dns").Value)[2]
#        Write-Host "- DNS Should be: $PDNS, $SDNS, $TDNS"

        if($PrimaryDNSServer -ne $PDNS) { 
            $PDNSBad = $true
        }
        if($SecondaryDNSServer -ne $SDNS) { 
            $SDNSBad = $true
        }                
        if($ThirdDNSServer -ne $TDNS) { 
            $TDNSBad = $true
        } 
        
        
        if ($PDNSBad -eq $true -or $SDNSBad -eq $true -or $TDNSBad -eq $true) {
            Write-Host "- Interface ID: $INTIndex"
            Write-Host "- IP Address: $IPAddr"
            Write-Host "- DHCP Enabled: $IsDHCPEnabled"
            Write-Host "- DNS 1: $PrimaryDNSServer"
            Write-Host "- DNS 2: $SecondaryDNSServer"
            Write-Host "- DNS 3: $ThirdDNSServer"
            Write-Host "- DNS Should be: $PDNS, $SDNS, $TDNS"
            if ($IsDHCPEnabled -eq $true ) {
                Write-Host "- DNS Servers not set correctly, DHCP is ENABLED, Change DHCP Server Options, No Changes Made." -ForegroundColor Red
                write-host "-----"
            } else {
                Write-Host "- DNS Servers not set correctly, setting DNS servers" -ForegroundColor Yellow
                write-host "-----"
#                    Invoke-Command -ComputerName $server -ScriptBlock { Set-DnsClientServerAddress -InterfaceIndex $using:INTIndex -ServerAddresses ("$using:PDNS","$using:SDNS","$using:TDNS") }
                
            }
        } else {
                    Write-Host "All DNS Servers set correctly" -ForegroundColor Green
                    write-host "-----"
        }
    }
}
