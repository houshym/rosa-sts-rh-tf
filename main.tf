#
# Copyright (c) 2022 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }
    ocm = {
      version = ">= 0.0.2"
      source  = "terraform-redhat/ocm"
    }
  }
}

provider "ocm" {
  token = var.token
  url = var.url
}

locals {
  sts_roles = {
      role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Installer-Role",
      support_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Support-Role",
      instance_iam_roles = {
        master_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-ControlPlane-Role",
        worker_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ManagedOpenShift-Worker-Role"
      },
      operator_role_prefix = var.operator_role_prefix,
  }
}

data "aws_caller_identity" "current" {
}

resource "ocm_cluster_rosa_classic" "rosa_sts_cluster" {
  name           = var.cluster-name
  cloud_region   = var.cloud-region
  aws_account_id     = data.aws_caller_identity.current.account_id
  availability_zones = [var.cloud-azs]
  properties = {
    rosa_creator_arn = data.aws_caller_identity.current.arn
  }
  sts = local.sts_roles
}

output oidc_endpoint_url {
  value = ocm_cluster_rosa_classic.rosa_sts_cluster.sts.oidc_endpoint_url
}
output thumbprint {
   value = ocm_cluster_rosa_classic.rosa_sts_cluster.sts.thumbprint
}

data "ocm_rosa_operator_roles" "operator_roles" {
  operator_role_prefix = var.operator_role_prefix
  account_role_prefix = var.account_role_prefix
}




locals {
  oidc_url = ocm_cluster_rosa_classic.rosa_sts_cluster.sts.oidc_endpoint_url
  thumbprint = ocm_cluster_rosa_classic.rosa_sts_cluster.sts.thumbprint
}

resource "null_resource" "sts_check" {
  triggers = {
    oidc_url = local.oidc_url
    thumbprint = local.thumbprint
  }
}

resource "null_resource" "pause" {
  provisioner "local-exec" {
    command = "sleep 60"
  }
}

module operator_roles {
  source = "terraform-redhat/rosa-sts/aws"
  version = "0.0.1"

  cluster_id = ocm_cluster_rosa_classic.rosa_sts_cluster.id
  rh_oidc_provider_thumbprint = local.thumbprint
  rh_oidc_provider_url = local.oidc_url
  operator_roles_properties = data.ocm_rosa_operator_roles.operator_roles.operator_iam_roles

  depends_on = [
    null_resource.pause
  ]
}


