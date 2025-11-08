# Canary Deployment Script for Windows PowerShell
# Manages gradual traffic shift from stable to canary version

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('10','30','50','100','status','rollback')]
    [string]$Action = 'status'
)

$NAMESPACE = "aceest-fitness"
$STABLE_DEPLOYMENT = "aceest-fitness-stable"
$CANARY_DEPLOYMENT = "aceest-fitness-canary"

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Canary Deployment Manager" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host ""

# Function to calculate replicas for percentage
function Get-Replicas {
    param([int]$Percentage)
    
    $totalPods = 10
    $canaryPods = [math]::Round($totalPods * $Percentage / 100)
    $stablePods = $totalPods - $canaryPods
    
    return @{
        Stable = $stablePods
        Canary = $canaryPods
        Percentage = $Percentage
    }
}

# Function to set traffic split
function Set-TrafficSplit {
    param([int]$Percentage)
    
    $replicas = Get-Replicas -Percentage $Percentage
    
    Write-Host "Setting traffic split: $Percentage percent to Canary, $($100-$Percentage) percent to Stable" -ForegroundColor Cyan
    Write-Host "  Stable pods: $($replicas.Stable)" -ForegroundColor Blue
    Write-Host "  Canary pods: $($replicas.Canary)" -ForegroundColor Yellow
    Write-Host ""
    
    # Scale deployments
    kubectl scale deployment $STABLE_DEPLOYMENT -n $NAMESPACE --replicas=$($replicas.Stable)
    kubectl scale deployment $CANARY_DEPLOYMENT -n $NAMESPACE --replicas=$($replicas.Canary)
    
    Write-Host "✓ Traffic split updated!" -ForegroundColor Green
    
    # Wait for rollout
    Write-Host ""
    Write-Host "Waiting for deployments to be ready..." -ForegroundColor Yellow
    kubectl rollout status deployment/$STABLE_DEPLOYMENT -n $NAMESPACE --timeout=60s
    kubectl rollout status deployment/$CANARY_DEPLOYMENT -n $NAMESPACE --timeout=60s
}

# Function to rollback (100% stable)
function Invoke-Rollback {
    Write-Host "Rolling back to 100% stable version..." -ForegroundColor Red
    Set-TrafficSplit -Percentage 0
    Write-Host ""
    Write-Host "✓ Rollback complete - all traffic on stable version" -ForegroundColor Green
}

# Function to show status
function Show-Status {
    Write-Host "Current Status:" -ForegroundColor Yellow
    Write-Host ""
    
    # Get replica counts
    $stableReplicas = kubectl get deployment $STABLE_DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>$null
    $canaryReplicas = kubectl get deployment $CANARY_DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.replicas}' 2>$null
    
    if ($stableReplicas -and $canaryReplicas) {
        $total = [int]$stableReplicas + [int]$canaryReplicas
        $canaryPercent = if ($total -gt 0) { [math]::Round(([int]$canaryReplicas / $total) * 100) } else { 0 }
        $stablePercent = 100 - $canaryPercent
        
        Write-Host "Traffic Distribution:" -ForegroundColor Cyan
        Write-Host "  [STABLE] $stablePercent percent ($stableReplicas pods)" -ForegroundColor Blue
        Write-Host "  [CANARY] $canaryPercent percent ($canaryReplicas pods)" -ForegroundColor Yellow
        Write-Host ""
    }
    
    Write-Host "Stable Deployment:" -ForegroundColor Blue
    kubectl get deployment $STABLE_DEPLOYMENT -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  Not deployed" }
    Write-Host ""
    
    Write-Host "Canary Deployment:" -ForegroundColor Yellow
    kubectl get deployment $CANARY_DEPLOYMENT -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  Not deployed" }
    Write-Host ""
    
    Write-Host "Pods:" -ForegroundColor Cyan
    kubectl get pods -n $NAMESPACE -l app=aceest-fitness --show-labels 2>$null
}

# Main logic
Write-Host "Action: $Action" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    '10' {
        Write-Host "Phase 1: Initial Canary Release (10 percent)" -ForegroundColor Yellow
        Set-TrafficSplit -Percentage 10
    }
    '30' {
        Write-Host "Phase 2: Increase Canary Traffic (30 percent)" -ForegroundColor Yellow
        Set-TrafficSplit -Percentage 30
    }
    '50' {
        Write-Host "Phase 3: Equal Split (50 percent)" -ForegroundColor Yellow
        Set-TrafficSplit -Percentage 50
    }
    '100' {
        Write-Host "Phase 4: Full Canary Rollout (100 percent)" -ForegroundColor Yellow
        Set-TrafficSplit -Percentage 100
        Write-Host ""
        Write-Host "Success! Canary is now the new stable version!" -ForegroundColor Green
        Write-Host "   You can now update the stable deployment to this version" -ForegroundColor Gray
    }
    'rollback' {
        Write-Host "Rolling back to 100% stable version..." -ForegroundColor Red
        Set-TrafficSplit -Percentage 0
        Write-Host ""
        Write-Host "Rollback complete - all traffic on stable version" -ForegroundColor Green
    }
    'status' {
        Show-Status
        exit 0
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Show-Status
