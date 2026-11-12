terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "actual" {}

locals {
  nombre_bucket    = var.nombre_bucket != "" ? var.nombre_bucket : "entregas-${var.sufijo}-${data.aws_caller_identity.actual.account_id}"
  nombre_base      = "entregas_${var.sufijo}_db"
  nombre_tabla     = "entregas_${var.sufijo}"
  nombre_workgroup = "entregas-${var.sufijo}-wg"

  etiquetas = {
    proyecto = "final-ingenieria-datos"
    autor    = var.sufijo
  }
}

# 1. Bucket S3 privado con bloqueo de acceso publico
resource "aws_s3_bucket" "datos" {
  bucket        = local.nombre_bucket
  force_destroy = true
  tags          = local.etiquetas
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket                  = aws_s3_bucket.datos.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Prefijos separados: datos y resultados de Athena
resource "aws_s3_object" "prefijo_entregas" {
  bucket  = aws_s3_bucket.datos.id
  key     = "entregas/"
  content = ""
}

resource "aws_s3_object" "prefijo_resultados" {
  bucket  = aws_s3_bucket.datos.id
  key     = "resultados-athena/"
  content = ""
}

# 3. Base de datos de Glue Data Catalog
resource "aws_glue_catalog_database" "entregas" {
  name        = local.nombre_base
  description = "Base de datos del examen final: entregas de mensajeria"
}

# 4. Tabla externa con partition projection por fecha
resource "aws_glue_catalog_table" "entregas" {
  name          = local.nombre_tabla
  database_name = aws_glue_catalog_database.entregas.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                       = "TRUE"
    classification                 = "csv"
    "skip.header.line.count"       = "1"
    "projection.enabled"           = "true"
    "projection.fecha.type"        = "date"
    "projection.fecha.format"      = "yyyy-MM-dd"
    "projection.fecha.range"       = "${var.fecha_inicial},${var.fecha_final}"
    "projection.fecha.interval"    = "1"
    "projection.fecha.interval.unit" = "DAYS"
    "storage.location.template"    = "s3://${aws_s3_bucket.datos.bucket}/entregas/fecha=$${fecha}/"
  }

  partition_keys {
    name = "fecha"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.datos.bucket}/entregas/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    columns {
      name = "id_envio"
      type = "string"
    }

    columns {
      name = "ciudad"
      type = "string"
    }

    columns {
      name = "transportadora"
      type = "string"
    }

    columns {
      name = "estado"
      type = "string"
    }

    columns {
      name = "duracion_minutos"
      type = "int"
    }
  }
}

# 5. Workgroup de Athena con resultados en resultados-athena/
resource "aws_athena_workgroup" "entregas" {
  name          = local.nombre_workgroup
  force_destroy = true
  tags          = local.etiquetas

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }

    result_configuration {
      output_location = "s3://${aws_s3_bucket.datos.bucket}/resultados-athena/"
    }
  }

  depends_on = [aws_s3_object.prefijo_resultados]
}
