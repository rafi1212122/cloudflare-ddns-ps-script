$cf_zone_id = '' <# your domain zone id #>
$cf_acc_email = '' <# your cloudflare email #>
$cf_api_token = '' <# https://dash.cloudflare.com/profile/api-tokens #>
$record_name = '' <# ex: dns.example.com #>
$record_type = '' <# AAAA for ipv6 or A for ipv4 #>

$get_ip = Invoke-WebRequest https://cloudflare.com/cdn-cgi/trace | findstr ip=
$ip = $get_ip.Split("=")[1]

$get_record_id = Invoke-WebRequest -Uri "https://api.cloudflare.com/client/v4/zones/$cf_zone_id/dns_records?type=$record_type&name=$record_name" -Headers @{'X-Auth-Email' = $cf_acc_email; 'Authorization' = "Bearer $cf_api_token"; 'Content-Type' = "application/json"} -Method Get
$record_id_res = ConvertFrom-Json -InputObject $get_record_id.content
$record_id = $record_id_res.result.id


if (($record_type-eq'AAAA')-and($ip -notmatch "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$|^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$|^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?$")) {
    Write-Host "invalid ip! , your ip: $ip"
    exit
}elseif (($record_type-eq'A')-and($ip -notmatch "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$")) {
    Write-Host "invalid ip! , your ip: $ip"
    exit
}

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

Write-Host $ip',' Success = $change_record_res.success
