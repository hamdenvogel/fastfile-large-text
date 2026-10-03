$content = Get-Content -Path "MainUnit.pas" -Encoding Default
$matches = $content | Select-String -Pattern 'ListView1'
$matches | Set-Content "listview1_pas.txt" -Encoding UTF8

$contentDfm = Get-Content -Path "MainUnit.dfm" -Encoding Default
$matchesDfm = $contentDfm | Select-String -Pattern 'ListView1'
$matchesDfm | Set-Content "listview1_dfm.txt" -Encoding UTF8
