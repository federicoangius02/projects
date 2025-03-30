resource "aws_codepipeline" "web_app_pipeline" {
    name     = "web-app-pipeline"
    role_arn = aws_iam_role.codepipeline_role.arn

    artifact_store {
        type     = "S3"
        location = aws_s3_bucket.codepipeline_bucket.bucket
    }

    stage {
        name = "Source"

        action {
            name             = "GitHub_Source"
            category         = "Source"
            owner            = "ThirdParty"
            provider         = "GitHub"
            version          = "1"
            output_artifacts = ["source_output"]

            configuration = {
                Owner      = "your-github-username"
                Repo       = "your-repo-name"
                Branch     = "main"
                OAuthToken = var.github_oauth_token
            }
        }
    }

    stage {
        name = "Build"

        action {
            name             = "CodeBuild"
            category         = "Build"
            owner            = "AWS"
            provider         = "CodeBuild"
            version          = "1"
            input_artifacts  = ["source_output"]
            output_artifacts = ["build_output"]

            configuration = {
                ProjectName = aws_codebuild_project.web_app_build.name
            }
        }
    }

    stage {
        name = "Deploy"

        action {
            name            = "Deploy"
            category        = "Deploy"
            owner           = "AWS"
            provider        = "CodeDeploy"
            version         = "1"
            input_artifacts = ["build_output"]

            configuration = {
                ApplicationName = aws_codedeploy_app.web_app.name
                DeploymentGroupName = aws_codedeploy_deployment_group.web_app_group.name
            }
        }
    }
}