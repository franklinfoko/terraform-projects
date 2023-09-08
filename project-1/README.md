Terraform AWS provider version 5
```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1
}
```

commands

```
terraform init  
terraform plan  
terrform apply  
terraform destroy
```