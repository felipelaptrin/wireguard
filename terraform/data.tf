data "template_file" "user_data" {
  template = file("${path.module}/template/user_data.sh")
  vars = {
    api_key = var.api_key
  }
}
