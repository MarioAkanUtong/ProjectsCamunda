module "network" {
  source   = "./modules/network"
  vpc_cidr = "10.0.0.0/16"
  env      = var.env
}

module "compute" {
  source        = "./modules/compute"
  ami_id        = "ami-123456"
  instance_type = "t3.micro"
  subnet_id     = "subnet-abc123"
  env           = var.env
}

module "storage" {
  source      = "./modules/storage"
  bucket_name = "app-storage"
  env         = var.env
}
