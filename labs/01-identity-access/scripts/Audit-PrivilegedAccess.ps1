<#
.SYNOPSIS
    Read-only Entra privileged-role hygiene report.

.DESCRIPTION
    Lists members of high-impact directory roles, flags guest accounts,
    and writes CSV. Does not add or remove role assignments.

    Requires Microsoft.Graph.Identity.DirectoryManagement and
    Microsoft.Graph.Users (or the combined Microsoft.Graph module).

.PARAMETER ReadDirectoryRoles
    Role template IDs to inspect. Defaults to Global Admin, Privileged
    Role Admin, Security Admin, User Admin.

.PARAMETER OutputPath
    CSV path. Default: privileged-audit-<date>.csv in the working directory.

.EXAMPLE
    Connect-MgGraph -Scopes "RoleManagement.Read.Directory","User.Read.All"
    ./Audit-PrivilegedAccess.ps1 -OutputPath ./out.csv
#>
[CmdletBinding()]
param(
    [string[]]$RoleTemplateIds = @(
        "62e90394-69f5-4237-9190-012177145e10", # Global Administrator
        "e8611ab8-c189-46e8-94e1-8229ab1aa571", # Privileged Role Administrator
        "194ae4cb-b126-40b2-bd5b-6091b380977d", # Security Administrator
        "fe930be7-5e62-47db-91af-98c3a49a38b1"  # User Administrator
    ),
    [string]$OutputPath = $(Join-Path -Path (Get-Location) -ChildPath ("privileged-audit-{0:yyyyMMdd}.csv" -f (Get-Date)))
)

$ErrorActionPreference = "Stop"

$context = Get-MgContext
if (-not $context) {
    throw "Not connected. Run Connect-MgGraph -Scopes 'RoleManagement.Read.Directory','User.Read.All'."
}

$findings = New-Object System.Collections.Generic.List[object]
$roles = Get-MgDirectoryRole -All

foreach ($role in $roles) {
    if ($RoleTemplateIds -and $role.RoleTemplateId -and ($RoleTemplateIds -notcontains $role.RoleTemplateId)) {
        continue
    }

    $members = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All
    if (-not $members) {
        $findings.Add([pscustomobject]@{
                RoleName         = $role.DisplayName
                RoleTemplateId   = $role.RoleTemplateId
                PrincipalId      = ""
                DisplayName      = "(no standing members)"
                UserType         = ""
                UserPrincipalName = ""
                Finding          = "Empty standing role — confirm PIM eligibility is the intended model"
            })
        continue
    }

    foreach ($member in $members) {
        $user = $null
        try {
            $user = Get-MgUser -UserId $member.Id -Property "displayName,userType,userPrincipalName,accountEnabled,onPremisesSyncEnabled" -ErrorAction Stop
        }
        catch {
            $findings.Add([pscustomobject]@{
                    RoleName          = $role.DisplayName
                    RoleTemplateId    = $role.RoleTemplateId
                    PrincipalId       = $member.Id
                    DisplayName       = $member.AdditionalProperties["displayName"]
                    UserType          = $member.AdditionalProperties["@odata.type"]
                    UserPrincipalName = ""
                    Finding           = "Non-user principal (group, SP, or unknown) holds a privileged role"
                })
            continue
        }

        $notes = @()
        if ($user.UserType -eq "Guest") { $notes += "GUEST in privileged role" }
        if ($user.AccountEnabled -eq $false) { $notes += "disabled account still assigned" }
        if ($user.OnPremisesSyncEnabled -and $role.DisplayName -match "Global Administrator") {
            $notes += "synced user as Global Admin — prefer a cloud-only break-glass"
        }
        if (-not $notes) { $notes += "standing assignment — confirm PIM eligible is not required" }

        $findings.Add([pscustomobject]@{
                RoleName          = $role.DisplayName
                RoleTemplateId    = $role.RoleTemplateId
                PrincipalId       = $user.Id
                DisplayName       = $user.DisplayName
                UserType          = $user.UserType
                UserPrincipalName = $user.UserPrincipalName
                Finding           = ($notes -join "; ")
            })
    }
}

$findings | Sort-Object RoleName, UserType, DisplayName | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
Write-Host "Wrote $($findings.Count) row(s) to $OutputPath"
$findings | Format-Table RoleName, UserType, UserPrincipalName, Finding -AutoSize
