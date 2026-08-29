# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

resource "aws_s3_bucket" "seir_bucket" {
  bucket = "seir-s3-950876749850"

  tags = {
    Name    = "Seir"
    Project = "Lab12b"
  }
}