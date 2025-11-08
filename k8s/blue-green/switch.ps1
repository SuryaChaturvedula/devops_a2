# Blue-Green Deployment Script for Windows PowerShell
# This script manages switching traffic between blue and green deployments

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('blue','green','status')]
    [string]$Action
)

$NAMESPACE = "aceest-fitness"
$SERVICE = "aceest-fitness-bluegreen"

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "Blue-Green Deployment Manager" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# Function to get current deployment
function Get-CurrentDeployment {
    $current = kubectl get service $SERVICE -n $NAMESPACE -o jsonpath='{.spec.selector.deployment}' 2>$null
    return $current
}

# Function to switch to blue
function Switch-ToBlue {
    Write-Host "Switching traffic to BLUE deployment..." -ForegroundColor Blue
    kubectl patch service $SERVICE -n $NAMESPACE -p '{\"spec\":{\"selector\":{\"deployment\":\"blue\"}}}'
    Write-Host "✓ Traffic now routed to BLUE" -ForegroundColor Blue
}

# Function to switch to green
function Switch-ToGreen {
    Write-Host "Switching traffic to GREEN deployment..." -ForegroundColor Green
    kubectl patch service $SERVICE -n $NAMESPACE -p '{\"spec\":{\"selector\":{\"deployment\":\"green\"}}}'
    Write-Host "✓ Traffic now routed to GREEN" -ForegroundColor Green
}

# Function to show status
function Show-Status {
    $current = Get-CurrentDeployment
    Write-Host ""
    Write-Host "Current Status:" -ForegroundColor Yellow
    Write-Host "  Active Deployment: $current"
    Write-Host ""
    Write-Host "Blue Deployment:" -ForegroundColor Blue
    kubectl get deployment aceest-fitness-blue -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  Not deployed" }
    Write-Host ""
    Write-Host "Green Deployment:" -ForegroundColor Green
    kubectl get deployment aceest-fitness-green -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  Not deployed" }
    Write-Host ""
    Write-Host "Service:" -ForegroundColor Cyan
    kubectl get service $SERVICE -n $NAMESPACE 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  Not found" }
}

# Main logic
switch ($Action) {
    'blue' {
        Write-Host "Switching traffic to BLUE deployment..." -ForegroundColor Blue
        kubectl patch service $SERVICE -n $NAMESPACE -p '{\"spec\":{\"selector\":{\"deployment\":\"blue\"}}}'
        Write-Host "✓ Traffic now routed to BLUE" -ForegroundColor Blue
    }
    'green' {
        Write-Host "Switching traffic to GREEN deployment..." -ForegroundColor Green
        kubectl patch service $SERVICE -n $NAMESPACE -p '{\"spec\":{\"selector\":{\"deployment\":\"green\"}}}'
        Write-Host "✓ Traffic now routed to GREEN" -ForegroundColor Green
    }
    'status' {
        Show-Status
        return
    }
}

Write-Host ""
Show-Status
