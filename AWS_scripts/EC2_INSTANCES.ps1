#################################
#
# Manage Instances in VPC -
# @Author: EPS Cloud | Ben Towner | Cloud Charmer
# @Date: 04/02/2016
#
# 1. Update Security groups
# 2. Setup instances in scripted VPC
#
#################################

param
(
    [string][parameter(mandatory=$true)]$VPCID
)

$VPCFilter = New-Object Amazon.EC2.Model.Filter
$VPCFilter.Name = 'vpc-id'
$VPCFilter.Value = $VPCID
$VPC = Get-EC2Vpc -VpcId $VPCID
$SUBNETS = Get-EC2Subnet -Filter $VPCFilter
$RT = Get-EC2RouteTable -Filter $VPCFilter
$ACL = Get-EC2NetworkAcl -Filter $VPCFilter
$SECURITY = Get-EC2SecurityGroup -Filter $VPCFilter
#
# Adding and Removing Rules
$RDPRule = New-Object Amazon.EC2.Model.IpPermission
$RDPRule.IpProtocol='tcp'
$RDPRule.FromPort=3389
$RDPRule.ToPort=3389
$RDPRule.IpRanges='0.0.0.0/0'

# Adding Http(s) rules
$HTTPRule = New-Object Amazon.EC2.Model.IpPermission
$HTTPRule.IpProtocol = 'tcp'
$HTTPRule.FromPort = 80
$HTTPRule.ToPort = 80
$HTTPRule.IpRanges = '0.0.0.0/0'

$HTTPSRule = New-Object Amazon.EC2.Model.IpPermission
$HTTPSRule.IpProtocol = 'tcp'
$HTTPSRule.FromPort = 443
$HTTPSRule.ToPort = 443
$HTTPSRule.IpRanges = '0.0.0.0/0'

Grant-EC2SecurityGroupIngress -GroupId $SECURITY.GroupId -IpPermissions $RDPRule, $HTTPRule, $HTTPSRule
#Revoke-EC2SecurityGroupIngress -GroupId $SECURITY.GroupId -IpPermission $RDPRule,$HTTPRule,$HTTPSRule

$Rule = New-Object Amazon.EC2.Model.IpPermission
$Rule.IpProtocol = '-1'
$Rule.IpRanges = '0.0.0.0/0'

Revoke-EC2SecurityGroupEgress -GroupId $SECURITY.GroupId -IpPermissions $Rule

$GroupId = New-EC2SecurityGroup -VpcId $VPCID -GroupName 'SQL' -Description 'Allows SQL Queries from the web server.'
$WebGroup = New-Object Amazon.EC2.Model.UserIdGroupPair
#$WebGroup.GroupId = 'sg-0dfaa775'
# sg-0dfaa775 is hardcoded -- find this progamatically

$SQLRule = New-Object Amazon.EC2.Model.IpPermission
$SQLRule.IpProtocol ='tcp'
$SQLRule.FromPort = 1433
$SQLRule.ToPort = 1433
$SQLRule.UserIdGroupPair = $WebGroup

Grant-EC2SecurityGroupIngress -GroupId $SECURITY.GroupId -IpPermissions $SQLRule

$PingRule = New-Object Amazon.EC2.Model.IpPermission
$PingRule.IpProtocol = 'icmp'
$PingRule.FromPort =8
$PingRule.ToPort = -1
$PingRule.IpRanges = '0.0.0.0/0'

Grant-EC2SecurityGroupIngress -GroupId $SECURITY.GroupId -IpPermissions $PingRule

$AMI = Get-EC2ImageByName -Name 'WINDOWS_2012_BASE'
#$AMI = Get-EC2ImageByName -Name 'VPC_NAT'

# Change the Max count to add # of instances
New-EC2Instance -ImageId $AMI[0].ImageId -KeyName 'Ben.Towner' -InstanceType 't2.micro' -MinCount 1 -MaxCount 1 -SubnetId $SUBNETS[0].SubnetId
