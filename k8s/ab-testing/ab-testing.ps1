# A/B Testing Deployment Script
# Manages traffic distribution between version A and B

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('status','test','split')]
    [string]$Action = 'status',
    
    [Parameter(Mandatory=$false)]
    [ValidateRange(0,100)]
    [int]$PercentageB = 50
)

$NAMESPACE = "aceest-fitness"
$VERSION_A_DEPLOYMENT = "aceest-fitness-version-a"
$VERSION_B_DEPLOYMENT = "aceest-fitness-version-b"
$SERVICE_A = "aceest-fitness-ab-version-a"
$SERVICE_B = "aceest-fitness-ab-version-b"

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "A/B Testing Deployment Manager" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

# Function to calculate replicas for A/B split
function Get-ABReplicas {
    param([int]$PercentageB)
    
    $totalPods = 6
    $podsB = [math]::Round($totalPods * $PercentageB / 100)
    $podsA = $totalPods - $podsB
    
    return @{
        VersionA = $podsA
        VersionB = $podsB
        PercentageA = [math]::Round(($podsA / $totalPods) * 100)
        PercentageB = [math]::Round(($podsB / $totalPods) * 100)
    }
}

# Function to set A/B traffic split
function Set-ABSplit {
    param([int]$PercentageB)
    
    $replicas = Get-ABReplicas -PercentageB $PercentageB
    
    Write-Host "Setting A/B traffic split..." -ForegroundColor Cyan
    Write-Host "  Version A (Control): $($replicas.PercentageA) percent ($($replicas.VersionA) pods)" -ForegroundColor Blue
    Write-Host "  Version B (Experiment): $($replicas.PercentageB) percent ($($replicas.VersionB) pods)" -ForegroundColor Green
    Write-Host ""
    
    # Scale deployments
    kubectl scale deployment $VERSION_A_DEPLOYMENT -n $NAMESPACE --replicas=$($replicas.VersionA)
    kubectl scale deployment $VERSION_B_DEPLOYMENT -n $NAMESPACE --replicas=$($replicas.VersionB)
    
    Write-Host "Traffic split updated!" -ForegroundColor Green
    
    # Wait for rollout
    Write-Host ""
    Write-Host "Waiting for deployments to be ready..." -ForegroundColor Yellow
    kubectl rollout status deployment/$VERSION_A_DEPLOYMENT -n $NAMESPACE --timeout=60s
    kubectl rollout status deployment/$VERSION_B_DEPLOYMENT -n $NAMESPACE --timeout=60s
}

# Function to test both versions
function Test-ABVersions {
    Write-Host "Testing both A and B versions..." -ForegroundColor Cyan
    Write-Host ""
    
    # Test Version A
    Write-Host "[Version A - Control Group]" -ForegroundColor Blue
    $podA = kubectl get pods -n $NAMESPACE -l version=a -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($podA) {
        $cmd = "python3 -c `"import urllib.request; r = urllib.request.urlopen('http://localhost:5000/health'); print(r.status)`""
        $resultA = kubectl exec $podA -n $NAMESPACE -- sh -c $cmd 2>$null
        Write-Host "  Health Check: $resultA" -ForegroundColor $(if ($resultA -eq "200") { "Green" } else { "Red" })
        
        $envCmd = "python3 -c `"import os; print(os.getenv('DEPLOYMENT_VERSION'))`""
        $versionA = kubectl exec $podA -n $NAMESPACE -- sh -c $envCmd 2>$null
        Write-Host "  Version: $versionA" -ForegroundColor Gray
    } else {
        Write-Host "  No pods found" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Test Version B
    Write-Host "[Version B - Test Group]" -ForegroundColor Green
    $podB = kubectl get pods -n $NAMESPACE -l version=b -o jsonpath='{.items[0].metadata.name}' 2>$null
    if ($podB) {
        $cmd = "python3 -c `"import urllib.request; r = urllib.request.urlopen('http://localhost:5000/health'); print(r.status)`""
        $resultB = kubectl exec $podB -n $NAMESPACE -- sh -c $cmd 2>$null
        Write-Host "  Health Check: $resultB" -ForegroundColor $(if ($resultB -eq "200") { "Green" } else { "Red" })
        
        $envCmd = "python3 -c `"import os; print(os.getenv('DEPLOYMENT_VERSION'))`""
        $versionB = kubectl exec $podB -n $NAMESPACE -- sh -c $envCmd 2>$null
        Write-Host "  Version: $versionB" -ForegroundColor Gray
    } else {
        Write-Host "  No pods found" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Simulating User Requests..." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Note: In production, you would:" -ForegroundColor Gray
    Write-Host "  1. Use cookie/header-based routing via Ingress" -ForegroundColor Gray
    Write-Host "  2. Assign users to A or B based on user ID hash" -ForegroundColor Gray
    Write-Host "  3. Track metrics (conversion, engagement) per variant" -ForegroundColor Gray
    Write-Host "  4. Use statistical significance testing" -ForegroundColor Gray
}

# Function to show status
function Show-Status {
    Write-Host "Current Status:" -ForegroundColor Yellow
    Write-Host ""
    
    # Get replica counts
    $replicasA = kubectl get deployment $VERSION_A_DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>$null
    $replicasB = kubectl get deployment $VERSION_B_DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>$null
    
    if ($replicasA -and $replicasB) {
        $total = [int]$replicasA + [int]$replicasB
        if ($total -gt 0) {
            $percentA = [math]::Round(([int]$replicasA / $total) * 100)
            $percentB = [math]::Round(([int]$replicasB / $total) * 100)
            
            Write-Host "Traffic Distribution:" -ForegroundColor Cyan
            Write-Host "  [A] Control: $percentA percent ($replicasA pods)" -ForegroundColor Blue
            Write-Host "  [B] Experiment: $percentB percent ($replicasB pods)" -ForegroundColor Green
            Write-Host ""
        }
    }
    
    Write-Host "Version A Deployment (Control):" -ForegroundColor Blue
    kubectl get deployment $VERSION_A_DEPLOYMENT -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  Not deployed" }
    Write-Host ""
    
    Write-Host "Version B Deployment (Experiment):" -ForegroundColor Green
    kubectl get deployment $VERSION_B_DEPLOYMENT -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  Not deployed" }
    Write-Host ""
    
    Write-Host "Services:" -ForegroundColor Cyan
    kubectl get service -n $NAMESPACE | Select-String "ab"
    Write-Host ""
    
    Write-Host "Pods:" -ForegroundColor Cyan
    kubectl get pods -n $NAMESPACE -l app=aceest-fitness --show-labels 2>$null | Select-String "version-a|version-b"
}

# Main logic
switch ($Action) {
    'split' {
        Write-Host "Setting $PercentageB percent traffic to Version B..." -ForegroundColor Cyan
        Set-ABSplit -PercentageB $PercentageB
    }
    'test' {
        Test-ABVersions
    }
    'status' {
        Show-Status
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Cyan
        Write-Host "  .\ab-testing.ps1 split -PercentageB 50  # 50/50 split" -ForegroundColor Gray
        Write-Host "  .\ab-testing.ps1 split -PercentageB 30  # 70% A, 30% B" -ForegroundColor Gray
        Write-Host "  .\ab-testing.ps1 test                   # Test both versions" -ForegroundColor Gray
        Write-Host "  .\ab-testing.ps1 status                 # Show current status" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
if ($Action -ne 'status') {
    Show-Status
}
