terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

// API Gateway
resource "google_api_gateway_api" "api_gw" {
  provider     = google-beta
  api_id       = "my-api"
  display_name = "sample-serverless-app-api-gateway"
}


// API Gateway Config
resource "google_api_gateway_api_config" "api_gw" {
  provider      = google-beta
  api           = google_api_gateway_api.api_gw.api_id
  api_config_id = "my-config"

  openapi_documents {
    document {
      path     = "api-gateway/openapi.yaml"
      contents = filebase64("api-gateway/openapi.yaml")
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

// API Gateway Gateway
resource "google_api_gateway_gateway" "api_gw" {
  provider   = google-beta
  region     = "us-central1"
  api_config = google_api_gateway_api_config.api_gw.id
  gateway_id = "my-gateway"
}

// Cloud function
resource "random_id" "default" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name                        = "${random_id.default.hex}-gcf-source"
  location                    = "US"
  uniform_bucket_level_access = true
}

data "archive_file" "default" {
  type        = "zip"
  source_dir  = "functions/"
  output_path = "/tmp/serverless-source.zip"
}

resource "google_storage_bucket_object" "object" {
  name   = "serverless-source.zip"
  bucket = google_storage_bucket.default.name
  source = data.archive_file.default.output_path
}

resource "google_cloudfunctions2_function" "default" {
  name        = "function-v2-python-serverless-app"
  location    = "us-central1"
  description = "serverless app"

  build_config {
    runtime     = "python311"
    entry_point = "main"
    source {
      storage_source {
        bucket = google_storage_bucket.default.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
}

// cloud function リソースが作成される前に実行されてしまう。
data "google_iam_policy" "invoker" {
  binding {
    role = "roles/run.invoker"
    members = [
      "user:メールアドレス",
    ]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "invoker" {
  location    = "us-central1"
  name        = "function-v2-python-serverless-app"
  policy_data = data.google_iam_policy.invoker.policy_data
}
