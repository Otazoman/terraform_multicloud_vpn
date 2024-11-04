# HA configuration VPN for 3 clouds (AWS, Azure and GoogleCloud)   

Rewrite the necessary parts of variables.tf  
Execute the following command  

```
terraform init
terraform plan
terraform apply
```

After completion, use the following command to obtain the Azure private key; for AWS, create the private key in advance.  
Connect from GoogleCloud and check for communication
```
terraform output -raw tls_private_key
```