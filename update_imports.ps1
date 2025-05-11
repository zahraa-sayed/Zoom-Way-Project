$files = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"
foreach ($file in $files) {
    $content = Get-Content $file.FullName
    $content = $content -replace 'package:yaaa_raab/', 'package:zoom_way/'
    Set-Content $file.FullName $content
} 