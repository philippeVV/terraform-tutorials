dependency "vpc" {
    config_path = "../eks"

    mock_outputs = {
        vpc_id = "temporary-dummy-vpc-id"
        public_subnets = ["temporary-dummy-subnet-id"]
    }
}

inputs = {
    vpc_id = dependency.vpc.outputs.vpc_id
    subnet_ids = dependency.vpc.outputs.public_subnets
}