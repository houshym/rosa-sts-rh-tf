variable cloud-region {
    type = string
    default = "us-east-2"
}

variable cloud-azs {
    type = string 
    default = "us-east-2a"   
}


variable token {
  type = string
  sensitive = true
  default = ""
}


variable cluster-name {
    type = string
    default = "rosa-sts-rh-tf"
}

variable cluster_id {
    type = string
    default = ""
}

variable oidc_endpoint_url {
    type = string
    default = ""
}

variable oidc_thumbprint {
    type = string
    default = ""
}

variable account_role_prefix {
    type = string
    default = ""
}
variable operator_role_prefix {
    type = string
    default = "mhs-tmp"
}

variable url {
    type = string
    default = "https://api.openshift.com"
}



