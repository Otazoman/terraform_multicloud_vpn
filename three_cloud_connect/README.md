# 3 cloud VPN interconnection between AWS, Azure and GCP  

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