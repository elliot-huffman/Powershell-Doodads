$output_file_name = "Internet Stress Test.log"
$ping_destination = "google.com"
$loop_counter = 0

do {

Test-Connection $ping_destination | Out-File $output_file_name -Append
$loop_counter ++
write-host "Number of ping batches: $loop_counter" | Out-File $output_file_name -Append
Start-Sleep -Seconds 60

} while ($true)
