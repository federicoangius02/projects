variable "github_token" {
  description = "Token OAuth per accedere al repository GitHub"
  type        = string
  sensitive   = true # Imposta come sensibile per nascondere il valore negli output
}