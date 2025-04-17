
<#
# Define source site credentials
$srcUsername = "upn@test.com"
$srcPasswordText = ""


$srcPassword = ConvertTo-SecureString $srcPasswordText -AsPlainText -Force

$TargetConn = Connect-Site -Url  https://test.sharepoint.com/sites/EcoTest -Username $srcUsername -Password $srcPassword


Connect-Site -Url  https://test.sharepoint.com/sites/sharegate_test_teamsite -UseCredentialsFrom $TargetConn

#>
<#

    <Mapping>
      <Source AccountName="allcompany@m365x76832558.onmicrosoft.com" DisplayName="allcompany@m365x76832558.onmicrosoft.com" PrincipalType="None" />
      <Destination AccountName="Spot_Sharegate_Test_TeamSite@test.onmicrosoft.com" DisplayName="Spot_Sharegate_Test_TeamSite@test.onmicrosoft.com" PrincipalType="SecurityGroup" />
    </Mapping>

    <Mapping>
      <Source AccountName="c:0t.c|tenant|8d35f930-8049-467e-ab93-d814ab451ae6" DisplayName="sg-Engineering" PrincipalType="SecurityGroup" />
      <Destination AccountName="c:0t.c|tenant|4c9e6a02-1475-4a10-b91f-a03c1f39abe6" DisplayName="ActivTrak Whitelist - Test" PrincipalType="SecurityGroup" />
    </Mapping>

    <Mapping>
      <Source AccountName="c:0t.c|tenant|8d35f930-8049-467e-ab93-d814ab451ae6" DisplayName="sg-Engineering" PrincipalType="SecurityGroup" />
      <Destination AccountName="c:0t.c|tenant|4c9e6a02-1475-4a10-b91f-a03c1f39abe6" DisplayName="ActivTrak Whitelist - Test" PrincipalType="SecurityGroup" />
    </Mapping>
#>
