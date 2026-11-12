output "region" {
  description = "Región de despliegue."
  value       = var.region
}

output "bucket" {
  description = "Bucket S3 del ejercicio."
  value       = aws_s3_bucket.datos.bucket
}

output "base_datos" {
  description = "Base de datos de Glue Data Catalog."
  value       = aws_glue_catalog_database.entregas.name
}

output "tabla" {
  description = "Tabla externa con partition projection."
  value       = aws_glue_catalog_table.entregas.name
}

output "workgroup" {
  description = "Workgroup de Athena."
  value       = aws_athena_workgroup.entregas.name
}

output "ubicacion_resultados" {
  description = "Ubicación de resultados de Athena."
  value       = "s3://${aws_s3_bucket.datos.bucket}/resultados-athena/"
}
