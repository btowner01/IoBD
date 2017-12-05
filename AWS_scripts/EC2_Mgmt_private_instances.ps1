#################################
#
# Manage Private Instances
# @Author: EPS Cloud | Ben Towner | Cloud Charmer
# @Date: 04/03/2016
#
# Using a RDP Gateway to access a SQL server in a private subnet, and return through the NAT
#
#################################

param
(
    [string][parameter(mandatory=$true)]$VPCID,
    [string][parameter(mandatory=$false)]$ResourcesSubnetCIDR = '10.2.0.0/24',
    [string][parameter(mandatory=$false)]$NAT_AMI,
    [string][parameter(mandatory=$false)]$RDP_AMI
)

# Set default NAT
If([System.String]::IsNullOrEmpty($NAT_AMI)){ $NAT_AMI = (Get-EC2ImageByName -Name 'WINDOWS_2012_BASE')[0].ImageId}
If([System.String]::IsNullOrEmpty($RDP_AMI)){ $RDP_AMI = (Get-EC2ImageByName -Name 'WINDOWS_2012_BASE')[0].ImageId}

$VPC = Get-EC2Vpc -VpcId $VPCID

#Choose first availability zone in the region
$AvailabilityZones = Get-EC2AvailabilityZone
$AvailabilityZone = $AvailabilityZones[0].ZoneName

#Create the resources subnet
$ResourcesSubnet = New-EC2Subnet -VpcId $VPCID -CidrBlock $ResourcesSubnetCIDR -AvailabilityZone $AvailabilityZone
$ResourcesRouteTable = New-EC2RouteTable -VpcId $VPC.VpcId

$VPCFilter = New-Object Amazon.EC2.Model.Filter
$VPCFilter.Name = 'attachment.vpc-id'
$VPCFilter.Value = $VPCID
$InternetGateway = Get-EC2InternetGateway -Filter $VPCID
New-EC2Route -RouteTableId $ResourcesRouteTable.RouteTableId -DestinationCidrBlock '0.0.0.0/0' -GatewayId $InternetGateway.InternetGatewayId
Register-EC2RouteTable -RouteTableId $ResourcesRouteTable.RouteTableId -SubnetId $ResourcesSubnet.SubnetId
