$cf_zone_id = '' <# your domain zone  id #>
$cf_acc_email = '' <# your cloudflare email #>
$cf_api_token = '' <# https://dash.cloudflare.com/profile/api-tokens #>
$record_name = '' <# ex: dns.example.com #>
$record_type = '' <# AAAA for ipv6 or A for ipv4 #>

$get_ip = Invoke-WebRequest https://cloudflare.com/cdn-cgi/trace | findstr ip=
$ip = $get_ip.Split("=")[1]

$get_record_id = Invoke-WebRequest -Uri "https://api.cloudflare.com/client/v4/zones/$cf_zone_id/dns_records?type=$record_type&name=$record_name" -Headers @{'X-Auth-Email' = $cf_acc_email; 'Authorization' = "Bearer $cf_api_token"; 'Content-Type' = "application/json"} -Method Get
$record_id_res = ConvertFrom-Json -InputObject $get_record_id.content
$record_id = $record_id_res.result.id

try {
    $change_record_req_body = @{
        'type' = $record_type;
        'name'  = $record_name;
        'content' = $ip;
        'ttl' = '1';
        'proxied' = $true;
    }
    $change_record_json_body = ConvertTo-Json -InputObject $change_record_req_body
    $change_record = Invoke-WebRequest -Uri "https://api.cloudflare.com/client/v4/zones/$cf_zone_id/dns_records/$record_id" -Headers @{'X-Auth-Email' = $cf_acc_email; 'Authorization' = "Bearer $cf_api_token"; 'Content-Type' = "application/json"} -Method Put -Body $change_record_json_body
    $change_record_res = ConvertFrom-Json -InputObject $change_record.content
}
catch {
    $respStream = $_.Exception.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($respStream)
    $respBody = $reader.ReadToEnd() | ConvertFrom-Json
    $respBody;
}

Write-Host $ip, $change_record_res
