output "budget_id" {
  description = "ID of the budget"
  value       = aws_budgets_budget.first_budget.id
}

output "budget_type" {
  description = "Public IP address of the EC2 instance"
  value       = aws_budgets_budget.first_budget.budget_type
}