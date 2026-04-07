# Define the reverse zone for the IP subnet 10.0.0.0/16
$reverseZone = "0.10.in-addr.arpa"

# Create the reverse lookup zone
Add-DnsServerPrimaryZone -NetworkID "10.0.0.0/16" -ZoneName $reverseZone


# Define the DNS zone and the desired number of records
$zoneName = "app.j2r.local"
$numberOfRecords = 50

# Create the dummy records
1..$numberOfRecords | ForEach-Object {
    $hostname = "dummy$_"
    $ipAddress = "10.0.$(($_ % 255)+1).$(($_ % 254)+1)" # Sample IP, adjust as needed
    Add-DnsServerResourceRecordA -ZoneName $zoneName -Name $hostname -IPv4Address $ipAddress -CreatePtr
}

Write-Host "Dummy records created successfully."
