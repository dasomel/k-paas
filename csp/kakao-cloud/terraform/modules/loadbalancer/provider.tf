terraform {
  required_version = ">= 1.13.5"
  required_providers {
    # Kakao Cloud Provider 설정
    kakaocloud = {
      source  = "kakaoenterprise/kakaocloud"
      version = "0.2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}
