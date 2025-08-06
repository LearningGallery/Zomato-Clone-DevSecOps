terraform {
  backend "s3" {
    bucket         = "zomato-devsecops-tfstate"
    key            = "dev/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}