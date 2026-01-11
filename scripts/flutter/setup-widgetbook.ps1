# PowerShell script to set up widgetbook structure for Flutter packages
# This script processes all Flutter packages in packages/frontend/flutter and:
# 1. Creates widgetbook/lib/ folder structure
# 2. Generates widgetbook/lib/main.dart entry point
# 3. Finds all *.usecase.dart files and generates corresponding *.stories.dart files

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Get the script directory and resolve base path
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "../..")
$FlutterPackagesPath = Join-Path $RepoRoot "packages/frontend/flutter"
$FlutterAppsPath = Join-Path $RepoRoot "apps/frontend/flutter"
$WidgetbookRootPath = Join-Path $RepoRoot "widgetbook"
$WidgetbookLibPath = Join-Path $WidgetbookRootPath "lib"

# Check if paths exist
$pathsToScan = @()
if (Test-Path $FlutterPackagesPath) {
    $pathsToScan += $FlutterPackagesPath
}
if (Test-Path $FlutterAppsPath) {
    $pathsToScan += $FlutterAppsPath
}

if ($pathsToScan.Count -eq 0) {
    Write-Error "No Flutter packages or apps found in expected locations"
    exit 1
}

Write-Host "[*] Scanning for Flutter packages and apps" -ForegroundColor Cyan
foreach ($path in $pathsToScan) {
    Write-Host "   - $path" -ForegroundColor Gray
}
Write-Host ""

# Function to calculate relative path between two absolute paths
function Get-RelativePath {
    param(
        [string]$FromPath,
        [string]$ToPath
    )

    $fromUri = New-Object System.Uri([System.IO.Path]::GetFullPath($FromPath) + "\")
    $toUri = New-Object System.Uri([System.IO.Path]::GetFullPath($ToPath) + "\")
    $relativeUri = $fromUri.MakeRelativeUri($toUri)
    $relativePath = [System.Uri]::UnescapeDataString($relativeUri.ToString())

    # Remove trailing slash if present
    if ($relativePath.EndsWith('/')) {
        $relativePath = $relativePath.Substring(0, $relativePath.Length - 1)
    }

    # Convert forward slashes to backslashes for Windows, or keep as is
    $relativePath = $relativePath -replace '/', '\'

    return $relativePath
}

# Function to extract package name from pubspec.yaml
function Get-PackageName {
    param([string]$PubspecPath)

    if (-not (Test-Path $PubspecPath)) {
        return $null
    }

    $content = Get-Content $PubspecPath -Raw
    if ($content -match 'name:\s+(\S+)') {
        return $matches[1].Trim()
    }

    return $null
}

# Function to extract widget type from usecase file
function Get-WidgetType {
    param([string]$UsecaseFilePath)

    if (-not (Test-Path $UsecaseFilePath)) {
        return $null
    }

    $content = Get-Content $UsecaseFilePath -Raw

    # Match @widgetbook.UseCase annotation with type field
    # Pattern: @widgetbook.UseCase( ... type: WidgetName, ... )
    if ($content -match '@widgetbook\.UseCase\s*\([^)]*type:\s*([^,\s\)]+)') {
        return $matches[1].Trim()
    }

    return $null
}

# Function to check if package has widgetbook dependencies
function Test-WidgetbookDependencies {
    param([string]$PubspecPath)

    if (-not (Test-Path $PubspecPath)) {
        return $false
    }

    $content = Get-Content $PubspecPath -Raw
    # Check for widgetbook, widgetbook_annotation, or widgetbook_generator
    return ($content -match 'widgetbook[_\w]*:') -or ($content -match 'widgetbook_annotation:') -or ($content -match 'widgetbook_generator:')
}

# Function to update package pubspec.yaml to add widgetbook dependencies
function Update-PackagePubspec {
    param(
        [string]$PubspecPath,
        [string]$WidgetbookPath,
        [switch]$Force
    )

    if (-not (Test-Path $PubspecPath)) {
        return $false
    }

    $lines = Get-Content $PubspecPath
    $newLines = @()
    $inDependencies = $false
    $inDevDependencies = $false
    $hasWidgetbookInDev = $false
    $hasWidgetbookWorkspaceInDev = $false
    $skipNextLine = $false
    $modified = $false
    $devDependenciesStartIndex = -1
    $devDependenciesEndIndex = -1

    # First pass: check what exists and find dev_dependencies boundaries
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^dev_dependencies:\s*$') {
            $devDependenciesStartIndex = $i
            $inDevDependencies = $true
        } elseif ($line -match '^(flutter|environment|name|version|description|publish_to):') {
            if ($inDevDependencies -and $devDependenciesEndIndex -eq -1) {
                $devDependenciesEndIndex = $i
            }
            $inDevDependencies = $false
        } elseif ($inDevDependencies) {
            if ($line -match '^\s*widgetbook:\s*') {
                $hasWidgetbookInDev = $true
            }
            if ($line -match '^\s*widgetbook_workspace:\s*') {
                $hasWidgetbookWorkspaceInDev = $true
            }
        }
    }

    # If dev_dependencies goes to end of file
    if ($inDevDependencies -and $devDependenciesEndIndex -eq -1) {
        $devDependenciesEndIndex = $lines.Count
    }

    # Second pass: build new content, removing old widgetbook dependencies
    $inDependencies = $false
    $inDevDependencies = $false
    $skipNextLine = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Track which section we're in
        if ($line -match '^dependencies:\s*$') {
            $inDependencies = $true
            $inDevDependencies = $false
            $newLines += $line
            continue
        } elseif ($line -match '^dev_dependencies:\s*$') {
            $inDependencies = $false
            $inDevDependencies = $true
            $newLines += $line
            continue
        } elseif ($line -match '^(flutter|environment|name|version|description|publish_to):') {
            $inDependencies = $false
            $inDevDependencies = $false
        }

        # Skip widgetbook_annotation and widgetbook_generator from anywhere
        if ($line -match '^\s*widgetbook_annotation:\s*' -or $line -match '^\s*widgetbook_generator:\s*') {
            $modified = $true
            continue
        }

        # Skip widgetbook from dependencies section only (not from dev_dependencies)
        if ($inDependencies -and $line -match '^\s*widgetbook:\s*') {
            $modified = $true
            continue
        }

        # Skip widgetbook_workspace from dependencies section only (not from dev_dependencies)
        if ($inDependencies -and $line -match '^\s*widgetbook_workspace:\s*') {
            $modified = $true
            $skipNextLine = $true  # Skip the path line too
            continue
        }

        # Skip path line if previous line was widgetbook_workspace
        if ($skipNextLine -and $line -match '^\s+path:\s*') {
            $skipNextLine = $false
            continue
        }
        $skipNextLine = $false

        $newLines += $line

        # Add widgetbook dependencies to dev_dependencies section before it ends
        if ($inDevDependencies -and $i -eq ($devDependenciesEndIndex - 1) -and $devDependenciesEndIndex -gt 0) {
            if (-not $hasWidgetbookInDev) {
                $newLines += "  widgetbook: ^4.0.0-alpha.4"
                $modified = $true
            }
            if (-not $hasWidgetbookWorkspaceInDev) {
                # Calculate relative path from package to root widgetbook folder
                $packageDir = Split-Path -Parent $PubspecPath
                $normalizedPackageDir = [System.IO.Path]::GetFullPath($packageDir)
                $normalizedWidgetbookPath = [System.IO.Path]::GetFullPath($WidgetbookPath)
                $relativeWidgetbookPath = Get-RelativePath -FromPath $normalizedPackageDir -ToPath $normalizedWidgetbookPath
                $relativeWidgetbookPath = $relativeWidgetbookPath -replace '\\', '/'

                $newLines += "  widgetbook_workspace:"
                $newLines += "    path: $relativeWidgetbookPath"
                $modified = $true
            }
        }
    }

    # Handle case where dev_dependencies is at the very end
    if ($devDependenciesEndIndex -eq $lines.Count -and $inDevDependencies) {
        if (-not $hasWidgetbookInDev) {
            $newLines += "  widgetbook: ^4.0.0-alpha.4"
            $modified = $true
        }
        if (-not $hasWidgetbookWorkspaceInDev) {
            $newLines += "  widgetbook_workspace:"
            $newLines += "    path: widgetbook"
            $modified = $true
        }
    }

    # If dev_dependencies section doesn't exist, create it
    if ($devDependenciesStartIndex -eq -1) {
        # Find where to insert dev_dependencies (after dependencies section or before flutter)
        $insertIndex = -1
        for ($i = 0; $i -lt $newLines.Count; $i++) {
            if ($newLines[$i] -match '^dependencies:\s*$') {
                # Find end of dependencies
                for ($j = $i + 1; $j -lt $newLines.Count; $j++) {
                    if ($newLines[$j] -match '^(dev_dependencies|flutter|environment|name|version|description|publish_to):') {
                        $insertIndex = $j
                        break
                    }
                }
                if ($insertIndex -eq -1) {
                    $insertIndex = $newLines.Count
                }
                break
            }
        }

        # If no dependencies section, find flutter section
        if ($insertIndex -eq -1) {
            for ($i = 0; $i -lt $newLines.Count; $i++) {
                if ($newLines[$i] -match '^flutter:\s*$') {
                    $insertIndex = $i
                    break
                }
            }
        }

        if ($insertIndex -ge 0) {
            $tempLines = @()
            for ($i = 0; $i -lt $newLines.Count; $i++) {
                $tempLines += $newLines[$i]
                if ($i -eq ($insertIndex - 1)) {
                    # Calculate relative path from package to root widgetbook folder
                    $packageDir = Split-Path -Parent $PubspecPath
                    $normalizedPackageDir = [System.IO.Path]::GetFullPath($packageDir)
                    $normalizedWidgetbookPath = [System.IO.Path]::GetFullPath($WidgetbookPath)
                    $relativeWidgetbookPath = Get-RelativePath -FromPath $normalizedPackageDir -ToPath $normalizedWidgetbookPath
                    $relativeWidgetbookPath = $relativeWidgetbookPath -replace '\\', '/'

                    $tempLines += ""
                    $tempLines += "dev_dependencies:"
                    $tempLines += "  widgetbook: ^4.0.0-alpha.4"
                    $tempLines += "  widgetbook_workspace:"
                    $tempLines += "    path: $relativeWidgetbookPath"
                    $modified = $true
                }
            }
            $newLines = $tempLines
        }
    }

    if ($modified) {
        Set-Content -Path $PubspecPath -Value $newLines -Encoding UTF8
        return $true
    }

    return $false
}

# Function to create widgetbook pubspec.yaml
function New-WidgetbookPubspec {
    param(
        [string]$OutputPath,
        [string[]]$PackageNames,
        [string]$RepoRoot
    )

    # Build dependencies section with all packages
    $dependenciesSection = "dependencies:`r`n  flutter:`r`n    sdk: flutter`r`n  widgetbook: ^4.0.0-alpha.4`r`n"

    foreach ($pkgName in $PackageNames) {
        # Calculate relative path from widgetbook to package/app
        # Search in both packages and apps directories
        $packageDirs = @()
        foreach ($searchPath in @("packages/frontend/flutter", "apps/frontend/flutter")) {
            $fullSearchPath = Join-Path $RepoRoot $searchPath
            if (Test-Path $fullSearchPath) {
                $foundDirs = Get-ChildItem -Path $fullSearchPath -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object {
                    $pubspecPath = Join-Path $_.FullName "pubspec.yaml"
                    if (Test-Path $pubspecPath) {
                        $pkgNameFromFile = Get-PackageName $pubspecPath
                        return $pkgNameFromFile -eq $pkgName
                    }
                    return $false
                }
                $packageDirs += $foundDirs
            }
        }

        if ($packageDirs.Count -gt 0) {
            $packageDir = $packageDirs[0].FullName
            $normalizedWidgetbookPath = [System.IO.Path]::GetFullPath((Split-Path -Parent $OutputPath))
            $normalizedPackageDir = [System.IO.Path]::GetFullPath($packageDir)
            $relativePackagePath = Get-RelativePath -FromPath $normalizedWidgetbookPath -ToPath $normalizedPackageDir
            $relativePackagePath = $relativePackagePath -replace '\\', '/'
            $dependenciesSection += "  $pkgName`:`r`n    path: $relativePackagePath`r`n"
        }
    }

    $pubspecContent = @"
name: widgetbook_workspace
description: A new Flutter project.
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ">=3.1.0 <4.0.0"

$dependenciesSection
flutter:
  uses-material-design: true
"@

    $pubspecDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $pubspecDir)) {
        New-Item -ItemType Directory -Path $pubspecDir -Force | Out-Null
    }

    Set-Content -Path $OutputPath -Value $pubspecContent -Encoding UTF8
    Write-Host "  [OK] Created: $OutputPath" -ForegroundColor Green
}

# Function to create widgetbook main.dart
function New-WidgetbookMain {
    param([string]$OutputPath)

    $mainContent = @'
import 'package:flutter/material.dart';

void main() {
  runApp(const WidgetbookApp());
}

class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Entry point for the app would be here
    return Placeholder();
  }
}
'@

    $mainDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $mainDir)) {
        New-Item -ItemType Directory -Path $mainDir -Force | Out-Null
    }

    Set-Content -Path $OutputPath -Value $mainContent -Encoding UTF8
    Write-Host "  [OK] Created: $OutputPath" -ForegroundColor Green
}

# Function to generate stories file
function New-StoriesFile {
    param(
        [string]$UsecaseFilePath,
        [string]$StoriesFilePath,
        [string]$PackageName,
        [string]$WidgetType,
        [string]$RelativePathFromLib
    )

    # Extract base filename without .usecase.dart
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($UsecaseFilePath)
    $filename = $filename -replace '\.usecase$', ''

    # Build package-relative import path
    # Convert Windows path separators to forward slashes for Dart imports
    $importPath = $RelativePathFromLib -replace '\\', '/'
    if ($importPath -and -not $importPath.EndsWith('/')) {
        $importPath += '/'
    }
    $packageImport = "package:$PackageName/$importPath$filename.dart"

    # Generate stories file content
    $storiesContent = @'
import 'package:flutter/material.dart';
import '{0}';
import 'package:widgetbook/widgetbook.dart';

part '{1}.stories.g.dart';

const metadata = ComponentMetadata(
  type: {2},
  name: '{2}',
);
'@ -f $packageImport, $filename, $WidgetType

    $storiesDir = Split-Path -Parent $StoriesFilePath
    if (-not (Test-Path $storiesDir)) {
        New-Item -ItemType Directory -Path $storiesDir -Force | Out-Null
    }

    if ((Test-Path $StoriesFilePath) -and -not $Force) {
        Write-Host "  [SKIP] Skipped (already exists): $StoriesFilePath" -ForegroundColor Yellow
        return
    }

    Set-Content -Path $StoriesFilePath -Value $storiesContent -Encoding UTF8
    Write-Host "  [OK] Created: $StoriesFilePath" -ForegroundColor Green
}

# Find all Flutter packages and apps recursively
# Search for all directories containing pubspec.yaml, then filter for those with lib/ folder
$allPackages = @()
foreach ($scanPath in $pathsToScan) {
    $allDirs = Get-ChildItem -Path $scanPath -Recurse -Directory -ErrorAction SilentlyContinue
    $packagesInPath = $allDirs | Where-Object {
        $pubspecPath = Join-Path $_.FullName "pubspec.yaml"
        $libPath = Join-Path $_.FullName "lib"
        (Test-Path $pubspecPath) -and (Test-Path $libPath)
    }
    $allPackages += $packagesInPath
}
$packages = $allPackages | Sort-Object FullName

if ($packages.Count -eq 0) {
    Write-Warning "No Flutter packages found in $FlutterPackagesPath"
    exit 0
}

Write-Host "[*] Found $($packages.Count) Flutter package(s)" -ForegroundColor Cyan
Write-Host ""

# Create root widgetbook folder structure
$widgetbookMainDartPath = Join-Path $WidgetbookLibPath "main.dart"
$widgetbookPubspecPath = Join-Path $WidgetbookRootPath "pubspec.yaml"

# Create widgetbook/lib/main.dart at root
if (-not (Test-Path $widgetbookMainDartPath) -or $Force) {
    New-WidgetbookMain -OutputPath $widgetbookMainDartPath
} else {
    Write-Host "[SKIP] Skipped (already exists): $widgetbookMainDartPath" -ForegroundColor Yellow
}

# Collect all packages with usecase files for pubspec.yaml
$packagesWithUsecases = @()

$totalStories = 0
$totalPackages = 0

foreach ($package in $packages) {
    $packageName = Get-PackageName (Join-Path $package.FullName "pubspec.yaml")
    if (-not $packageName) {
        Write-Warning "[!] Could not extract package name from: $($package.FullName)"
        continue
    }

    Write-Host "[*] Processing package: $packageName" -ForegroundColor Magenta
    Write-Host "   Path: $($package.FullName)" -ForegroundColor Gray

    $pubspecPath = Join-Path $package.FullName "pubspec.yaml"
    $libPath = Join-Path $package.FullName "lib"

    # Check if package has widgetbook dependencies
    $hasWidgetbookDeps = Test-WidgetbookDependencies -PubspecPath $pubspecPath

    # Find and delete widgetbook.generator.dart files
    $generatorFiles = Get-ChildItem -Path $package.FullName -Filter "widgetbook.generator.dart" -Recurse -ErrorAction SilentlyContinue
    foreach ($generatorFile in $generatorFiles) {
        if ($Force -or (Test-Path $generatorFile.FullName)) {
            Remove-Item -Path $generatorFile.FullName -Force
            Write-Host "  [OK] Deleted: $($generatorFile.FullName)" -ForegroundColor Green
        }
    }

    # Update package pubspec.yaml if it has widgetbook dependencies
    if ($hasWidgetbookDeps) {
        $updated = Update-PackagePubspec -PubspecPath $pubspecPath -WidgetbookPath $WidgetbookRootPath -Force:$Force
        if ($updated) {
            Write-Host "  [OK] Updated pubspec.yaml with widgetbook dependencies" -ForegroundColor Green
        } else {
            Write-Host "  [INFO] pubspec.yaml already has widgetbook dependencies" -ForegroundColor Gray
        }
    }

    # Find all usecase files
    $usecaseFiles = Get-ChildItem -Path $libPath -Filter "*.usecase.dart" -Recurse

    if ($usecaseFiles.Count -eq 0) {
        Write-Host "  [INFO] No usecase files found in this package" -ForegroundColor Gray
        Write-Host ""
        continue
    }

    # Add package to list for pubspec.yaml
    $packagesWithUsecases += $packageName

    # Calculate relative path from packages/frontend/flutter or apps/frontend/flutter to this package/app
    $normalizedPackagePath = [System.IO.Path]::GetFullPath($package.FullName)
    $relativeFromFlutter = $null

    # Check which base path this package belongs to
    foreach ($basePath in $pathsToScan) {
        $normalizedBasePath = [System.IO.Path]::GetFullPath($basePath)
        if ($normalizedPackagePath.StartsWith($normalizedBasePath)) {
            $relativeFromFlutter = $normalizedPackagePath.Substring($normalizedBasePath.Length)
            $relativeFromFlutter = $relativeFromFlutter.TrimStart('\', '/')
            break
        }
    }

    if (-not $relativeFromFlutter) {
        Write-Warning "  [!] Could not determine relative path for package: $($package.FullName)"
        continue
    }

    Write-Host "  [*] Found $($usecaseFiles.Count) usecase file(s)" -ForegroundColor Cyan

    $storiesCount = 0

    foreach ($usecaseFile in $usecaseFiles) {
        $widgetType = Get-WidgetType $usecaseFile.FullName

        if (-not $widgetType) {
            Write-Warning "  [!] Could not extract widget type from: $($usecaseFile.FullName)"
            continue
        }

        # Calculate relative path from lib/ to the usecase file
        $usecaseDir = $usecaseFile.DirectoryName
        $normalizedLibPath = [System.IO.Path]::GetFullPath($libPath)
        $normalizedUsecaseDir = [System.IO.Path]::GetFullPath($usecaseDir)

        if ($normalizedUsecaseDir.StartsWith($normalizedLibPath)) {
            $relativePathFromLib = $normalizedUsecaseDir.Substring($normalizedLibPath.Length)
            # Remove leading path separators
            $relativePathFromLib = $relativePathFromLib.TrimStart('\', '/')

            # Remove 'src' folder from the path if present
            if ($relativePathFromLib -match '^src[/\\]') {
                $relativePathFromLib = $relativePathFromLib -replace '^src[/\\]', ''
            } elseif ($relativePathFromLib -eq 'src') {
                $relativePathFromLib = ""
            }
        } else {
            $relativePathFromLib = ""
        }

        # Create stories file path in root widgetbook folder
        # Path structure: widgetbook/lib/{relativeFromFlutter}/{relativePathFromLib}/{filename}.stories.dart
        $storiesDir = $WidgetbookLibPath
        if ($relativeFromFlutter) {
            $storiesDir = Join-Path $storiesDir $relativeFromFlutter
        }
        if ($relativePathFromLib) {
            $storiesDir = Join-Path $storiesDir $relativePathFromLib
        }

        $filename = [System.IO.Path]::GetFileNameWithoutExtension($usecaseFile.Name)
        $filename = $filename -replace '\.usecase$', ''
        $storiesFilePath = Join-Path $storiesDir "$filename.stories.dart"

        # Generate stories file
        New-StoriesFile `
            -UsecaseFilePath $usecaseFile.FullName `
            -StoriesFilePath $storiesFilePath `
            -PackageName $packageName `
            -WidgetType $widgetType `
            -RelativePathFromLib $relativePathFromLib

        $storiesCount++
    }

    $totalStories += $storiesCount
    $totalPackages++
    Write-Host "  [OK] Generated $storiesCount stories file(s) for package $packageName" -ForegroundColor Green
    Write-Host ""
}

# Create widgetbook/pubspec.yaml with all packages
if ($packagesWithUsecases.Count -gt 0) {
    if (-not (Test-Path $widgetbookPubspecPath) -or $Force) {
        New-WidgetbookPubspec -OutputPath $widgetbookPubspecPath -PackageNames $packagesWithUsecases -RepoRoot $RepoRoot
    } else {
        Write-Host "[SKIP] Skipped (already exists): $widgetbookPubspecPath" -ForegroundColor Yellow
    }
}

Write-Host "[*] Summary" -ForegroundColor Cyan
Write-Host "   Packages processed: $totalPackages" -ForegroundColor White
Write-Host "   Stories files generated: $totalStories" -ForegroundColor White
Write-Host ""
Write-Host "[OK] Widgetbook setup complete!" -ForegroundColor Green
