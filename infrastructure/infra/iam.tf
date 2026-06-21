  //policy for eks to read ecr
data "aws_iam_policy" "read_ecr" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
//attach policy
resource "aws_iam_role_policy_attachment" "ecr_attachment" {
  role = module.eks.eks_managed_node_groups["example"].iam_role_name
  policy_arn = data.aws_iam_policy.read_ecr.arn
}

  