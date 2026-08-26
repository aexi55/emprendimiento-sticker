$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$assetRoot = Join-Path $projectRoot 'assets'
$indexPath = Join-Path $projectRoot 'index.html'
$temporaryRoot = Join-Path $projectRoot '.github-pages-assets-tmp'

function Convert-ToGithubName {
    param([string]$Value)

    $normalized = $Value.Normalize([Text.NormalizationForm]::FormD)
    $withoutMarks = [regex]::Replace($normalized, '\p{Mn}', '')
    $ascii = [regex]::Replace($withoutMarks, '[^\x00-\x7F]', '')
    $slug = [regex]::Replace($ascii.ToLowerInvariant(), '[^a-z0-9]+', '-')
    $slug = $slug.Trim('-')

    if ([string]::IsNullOrWhiteSpace($slug)) {
        throw "No se pudo crear un nombre seguro para: $Value"
    }

    return $slug
}

if (-not (Test-Path -LiteralPath $assetRoot)) {
    throw "No existe la carpeta assets: $assetRoot"
}

$files = Get-ChildItem -LiteralPath $assetRoot -File -Recurse
$usedTargets = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$moves = @()

foreach ($file in $files) {
    $relative = $file.FullName.Substring($assetRoot.Length).TrimStart('\')
    $segments = $relative -split '\\'
    $newSegments = @()

    for ($index = 0; $index -lt ($segments.Count - 1); $index++) {
        $newSegments += Convert-ToGithubName $segments[$index]
    }

    $baseName = [IO.Path]::GetFileNameWithoutExtension($segments[-1])
    $extension = [IO.Path]::GetExtension($segments[-1]).ToLowerInvariant()
    $newFileName = "$(Convert-ToGithubName $baseName)$extension"
    $newRelative = (@($newSegments) + $newFileName) -join '\'
    $targetKey = $newRelative.ToLowerInvariant()
    $suffix = 2

    while (-not $usedTargets.Add($targetKey)) {
        $newFileName = "$(Convert-ToGithubName $baseName)-$suffix$extension"
        $newRelative = (@($newSegments) + $newFileName) -join '\'
        $targetKey = $newRelative.ToLowerInvariant()
        $suffix++
    }

    $moves += [pscustomobject]@{
        Source = $file.FullName
        SourceRelative = $relative
        TargetRelative = $newRelative
    }
}

New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

try {
    foreach ($move in $moves) {
        $temporaryFile = Join-Path $temporaryRoot ([guid]::NewGuid().ToString() + [IO.Path]::GetExtension($move.Source))
        Move-Item -LiteralPath $move.Source -Destination $temporaryFile
        $move | Add-Member -NotePropertyName Temporary -NotePropertyValue $temporaryFile
    }

    foreach ($move in $moves) {
        $target = Join-Path $assetRoot $move.TargetRelative
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        Move-Item -LiteralPath $move.Temporary -Destination $target
    }
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}

$html = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
foreach ($move in ($moves | Sort-Object { $_.SourceRelative.Length } -Descending)) {
    $oldUrl = 'assets/' + ($move.SourceRelative -replace '\\', '/')
    $newUrl = 'assets/' + ($move.TargetRelative -replace '\\', '/')
    $html = $html.Replace($oldUrl, $newUrl)
}
Set-Content -LiteralPath $indexPath -Value $html -Encoding UTF8

Get-ChildItem -LiteralPath $assetRoot -Directory -Recurse |
    Sort-Object FullName -Descending |
    Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0 } |
    Remove-Item -Force

Write-Host "Renombrados $($moves.Count) archivos." -ForegroundColor Green
Write-Host "Formato aplicado: minusculas, ASCII, guiones y extensiones normalizadas." -ForegroundColor Green
Write-Host "Carpetas nuevas y nombres completos:" -ForegroundColor Cyan
$moves | Sort-Object TargetRelative | ForEach-Object { Write-Host ('  assets/' + ($_.TargetRelative -replace '\\', '/')) }