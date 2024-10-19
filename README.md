# Cloud to Cloud VPN Connection  
Building a cloud-to-cloud VPN with terraform  

# Description  
Sample for building VPN connection between AWS, Azure and GoogleCloud with terraform  

Three_cloud_connect is a terraform for 3-cloud interconnection and two_cloud_connect is a terraform for 2-cloud interconnection

# Operating environment  
Ubuntu 24.04.1 LTS  
Docker version 27.3.1  

# Usage    

1.Get AWS authentication information   
2.Get GoogleCloud serviceaccount information  
3.Get Azure Authentication Information  
4.Save the .env.sample file as .env after editing
5.Launch docker and run terraform in a container

```
docker compose up -d
docker compose exec terraform-vpn ash
```
