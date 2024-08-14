// Создание сервисного аккаунта для bucket
resource "yandex_iam_service_account" "sa-bucket" {
  folder_id = var.folder_id
  name      = "sa-bucket"
}

// Назначение роли editor сервисному аккаунту sa-bucket
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa-bucket.id}"
}

// Создание статического ключа доступа для sa-bucket
resource "yandex_iam_service_account_static_access_key" "sa-bucket-key" {
  service_account_id = yandex_iam_service_account.sa-bucket.id
  description        = "static access key for object storage"
}
// Создаем бакет используя ключи sa-bucket-key
resource "yandex_storage_bucket" "bucket-diplom" {
  access_key = yandex_iam_service_account_static_access_key.sa-bucket-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-bucket-key.secret_key
  bucket = "bucket-diplom"
}

// Создаем файл в проекте для подключения бакета и загрузки состояние терраформ
resource "local_file" "backend-1" {
  filename = "backet.tf"
  content  = <<-EOT
terraform {
  backend "s3" {
  endpoints   = {
    s3 = "https://storage.yandexcloud.net"
  }
  bucket     = "bucket-diplom"
  region     = "ru-central1"
  key        = "terraform.tfstate"
  access_key = "${yandex_iam_service_account_static_access_key.sa-bucket-key.access_key}"
  secret_key = "${yandex_iam_service_account_static_access_key.sa-bucket-key.secret_key}"
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_s3_checksum            = true
  }
}
EOT
}