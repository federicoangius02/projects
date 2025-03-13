provider "aws" {
  region = "eu-south-1"  # Regione di Milano
}

# Bucket S3 per gli artefatti di build
resource "aws_s3_bucket" "node_app_bucket" {
  bucket = "my-node-app-bucket-eu-south-1"  # Nome univoco per il bucket

  tags = {
    Name        = "My Node App Bucket"
    Environment = "Production"
  }
}

# Blocca l'accesso pubblico al bucket S3
resource "aws_s3_bucket_public_access_block" "node_app_bucket_block" {
  bucket = aws_s3_bucket.node_app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Ruolo IAM per CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

# Policy IAM per CodeBuild
resource "aws_iam_policy" "codebuild_policy" {
  name        = "codebuild-policy"
  description = "Policy per permettere a CodeBuild di accedere a S3 e altre risorse"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.node_app_bucket.arn,
          "${aws_s3_bucket.node_app_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# Allega la policy al ruolo CodeBuild
resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

# Progetto CodeBuild
resource "aws_codebuild_project" "node_app_build" {
  name          = "node-app-build"
  description   = "Progetto CodeBuild per l'app Node.js"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type  = "CODEBUILD"
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/tuo-username/my-node-app.git"  # Sostituisci con il tuo repository
    git_clone_depth = 1
  }

  source_version = "main"  # Usa il branch principale
}

# Ruolo IAM per CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}

# Policy IAM per CodePipeline
resource "aws_iam_policy" "codepipeline_policy" {
  name        = "codepipeline-policy"
  description = "Policy per permettere a CodePipeline di accedere a CodeBuild e S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.node_app_bucket.arn,
          "${aws_s3_bucket.node_app_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ],
        Resource = aws_codebuild_project.node_app_build.arn
      }
    ]
  })
}

# Allega la policy al ruolo CodePipeline
resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# CodePipeline
resource "aws_codepipeline" "node_app_pipeline" {
  name     = "node-app-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.node_app_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "tuo-username"  # Sostituisci con il tuo username GitHub
        Repo       = "my-node-app"   # Sostituisci con il nome del repository
        Branch     = "main"          # Usa il branch principale
        OAuthToken = var.github_token  # Token OAuth di GitHub (da configurare come variabile)
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.node_app_build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        BucketName = aws_s3_bucket.node_app_bucket.bucket
        Extract    = "true"
      }
    }
  }
}

# Output per l'URL della pipeline
output "pipeline_url" {
  value = "https://eu-south-1.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.node_app_pipeline.name}/view"
}