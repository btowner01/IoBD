#-----------------------------------------------------
#
# This will create a Virtual Private Cloud on AWS with 2 subnets, Public &
# Private, with the necessary virtual gateway, routing table and security.
#
# @Author: EPS Cloud | Ben Towner | Cloud Charmer
# @Date: 04/01/2016
#
# 1. Create a VPC
# 2. Create a DHCP option set
# 3. Create subnets
# 4. Add an Internet Gateway
# 5. Configure a routing table
# 6. Configure ACLs
#
#-----------------------------------------------------

param
(
    [string][parameter(mandatory=$true)]$DomainName,
    [string][parameter(mandatory=$false)]$VPCIDR = '10.2.0.0/16',
    [string][parameter(mandatory=$false)]$PublicSubnetCIDR = '10.2.0.0/24',
    [string][parameter(mandatory=$false)]$PrivateSubnetCIDR = '10.2.1.0/24'
)

## Set credentials for your AWS account
# I use a credential file from my AWS account, you need to update here
# $cmd = 'C:\Users\BenTownerNimbo\.aws\EPSCloud.ps1'
$cmd = '<Account login credential File location>'
Invoke-Expression "$cmd"

## After successfully logging in with Powershell
$a = Get-Date
$scriptDate =  $a.ToShortDateString()
$b = Get-Date -format MMM;
$scriptDetail = $scriptDate.Replace("/","_")


$VPC = New-EC2Vpc -CidrBlock $VPCIDR
Start-Sleep -s 15                     # Allow the Cloud to form overhead.

#Configure the DHCP Options using the default DNS provider
$Domain = New-Object Amazon.EC2.Model.DhcpConfiguration
$Domain.Key = 'domain-name'
$Domain.Value = $DomainName
$DNS = New-Object Amazon.EC2.Model.DhcpConfiguration
$DNS.Key = 'domain-name-servers'
$DNS.Value = 'AmazonProvidedDNS'
$DHCP = New-EC2DhcpOption -DhcpConfiguration $Domain, $DNS
Register-EC2DhcpOption -DhcpOptionsId $DHCP.DhcpOptionsId -VpcId $VPC.VpcId

#Choosing the first Availability zone in the region
$AvailabilityZones = Get-EC2AvailabilityZone
$AvailabilityZone = $AvailabilityZones[0].ZoneName

#Create and tag the Public subnet
$PublicSubnet = New-EC2Subnet -VpcId $VPC.VpcId -CidrBlock $PublicSubnetCIDR -AvailabilityZone $AvailabilityZone
Start-Sleep -s 15                     # Give them some time, gesh.
$Tag = New-Object Amazon.EC2.Model.Tag
$Tag.Key = 'Name'
$Tag.Value = 'BT_'+$scriptDetail+'_PublicScript'
New-EC2Tag -Resource $PublicSubnet.SubnetId -Tag $Tag

#Create and tag the Private subnet
$PrivateSubnet = New-EC2Subnet -VpcId $VPC.VpcId -CidrBlock $PrivateSubnetCIDR -AvailabilityZone $AvailabilityZone
Start-Sleep -s 15                     # Another break
$Tag = New-Object Amazon.EC2.Model.Tag
$Tag.Key = 'Name'
$Tag.Value = 'BT_'+$scriptDetail+'_PrivateScript'
New-EC2Tag -Resource $PrivateSubnet.SubnetId -Tag $Tag

#Add an Internet Gateway and attach it to the VPC
$VPCFilter = New-Object Amazon.EC2.Model.Filter
$VPCFilter.Name = 'attachment.vpc-id'
$VPCFilter.Value = $VPC.VpcId
$InternetGateway = New-EC2InternetGateway
Add-EC2InternetGateway -InternetGatewayId $InternetGateway.InternetGatewayId -VpcId $VPC.VpcId

#Create a new routeTable and associate it with the public subnet
$PublicRouteTable = New-EC2RouteTable -VpcId $VPC.VpcId
New-EC2Route -RouteTableId $PublicRouteTable.RouteTableId -DestinationCidrBlock '0.0.0.0/0' -GatewayId $InternetGateway.InternetGatewayId
$NoEcho = Register-EC2RouteTable -RouteTableId $PublicRouteTable.RouteTableId -SubnetId $PublicSubnet.SubnetId

# Create a new Access Control List for the public subnet
$PublicACL = New-EC2NetworkAcl -VpcId $VPC.VpcId
New-EC2NetworkAclEntry -NetworkAclId $PublicACL.NetworkAclId -RuleNumber 50 -CidrBlock $VPCIDR -Egress $false -PortRange_From 80 -PortRange_To 80 -Protocol 6 -RuleAction 'Deny'
New-EC2NetworkAclEntry -NetworkAclId $PublicACL.NetworkAclId -RuleNumber 50 -CidrBlock $VPCIDR -Egress $true -PortRange_From 49152 -PortRange_To 65535 -Protocol 6 -RuleAction 'Deny'
New-EC2NetworkAclEntry -NetworkAclId $PublicACL.NetworkAclId -RuleNumber 100 -CidrBlock '0.0.0.0/0' -Egress $false -PortRange_From 80 -PortRange_To 80 -Protocol 6 -RuleAction 'Allow'
New-EC2NetworkAclEntry -NetworkAclId $PublicACL.NetworkAclId -RuleNumber 100 -CidrBlock '0.0.0.0/0' -Egress $true -PortRange_From 49152 -PortRange_To 65535 -Protocol 6 -RuleAction 'Allow'
New-EC2NetworkAclEntry -NetworkAclId $PublicACL.NetworkAclId -RuleNumber 200 -CidrBlock $PrivateSubnetCIDR -Egress $true -PortRange_From 1433 -PortRange_To 1433 -Protocol 6 -RuleAction 'Allow'
New-EC2NetworkAclEntry -NetworkAclId $PublicACL.NetworkAclId -RuleNumber 200 -CidrBlock $PrivateSubnetCIDR -Egress $false -PortRange_From 49152 -PortRange_To 65535 -Protocol 6 -RuleAction 'Allow'
New-EC2NetworkAclEntry -NetworkAclId $PublicACL.NetworkAclId -RuleNumber 300 -CidrBlock '0.0.0.0/0' -Egress $false -PortRange_From 3389 -PortRange_To 3389 -Protocol 6 -RuleAction 'Allow'

# Associate the ACL to the public subnet
$VPCFilter.Name = 'vpc-id'
$DefaultFilter = New-Object Amazon.EC2.Model.Filter
$DefaultFilter.Name = 'default'
$DefaultFilter.Value = 'true'
$OldACL = (Get-EC2NetworkAcl -Filter $VPCFilter, $DefaultFilter)
$OldAssociation = $OldACL.Associations | Where-Object { $_.SubnetId -eq $PublicSubnet.SubnetId}
$NoEcho = Set-EC2NetworkAclAssociation -AssociationId $OldAssociation.NetworkAclAssociationId -NetworkAclId $PublicACL.NetworkAclId
# check this  $OldAssociation.NetworkAclAssociationId

# Log the most common IDs
Write-Host "This VPC ID : " $VPC.VpcId
Write-Host "The public subnet ID : " $PublicSubnet.SubnetId
Write-Host "The private subnet ID : " $PrivateSubnet.SubnetId
