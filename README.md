![alt text][eps]

# IoBD
**Interconnection of Big Data** - supporting material for the blog series
______
![alt text][aws_topo]  
Setup the Infrastructure need for an on-demand Analytics Platform.

1. Install the Infrastructure.  
  Get an Amazon AWS account  
  Use [CreateVirtualCloud.ps1](https://github.com/NimboCloud/IoBD/blob/master/AWS_scripts/CreateVirtualCloud.ps1?raw=true)  located in the AWS_Scripts folder (I know... I can't stand powershell either)  
2. Provision Spark  
3. Provision Zepplin with Spark Integration  
4. Obtain the Data  
	Create a twitter [application](https://apps.twitter.com/app/).  
		
5. Make majic happen  

![alt text][zep]

[eps]: https://github.com/NimboCloud/IoBD/blob/master/img/eps_logo.png?raw=true "Equinix Professional Services"
[aws_topo]: https://github.com/NimboCloud/IoBD/blob/master/img/network_topology.png?raw=true "Equinix Professional Services"
[zep]: https://github.com/NimboCloud/IoBD/blob/master/img/zeppelin.png?raw=true "Equinix Professional Services"
[vpc]: https://github.com/NimboCloud/IoBD/blob/master/AWS_scripts/CreateVirtualCloud.ps1?raw=true "Main Template"