data "template_file" "user_data" {
  template = file("${path.module}/template/user_data.sh")
  vars = {
    TOKEN_ID = var.api_key
  }
}
