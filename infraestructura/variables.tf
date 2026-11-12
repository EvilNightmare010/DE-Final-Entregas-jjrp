variable "region" {
  description = "Región de AWS donde se despliegan los recursos."
  type        = string
  default     = "us-east-2"
}

variable "sufijo" {
  description = "Siglas del estudiante que deben ir en el nombre de cada recurso."
  type        = string
  default     = "jjrp"
}

variable "nombre_bucket" {
  description = "Nombre del bucket. Si queda vacío se usa entregas-<sufijo>-<id de cuenta>."
  type        = string
  default     = ""
}

variable "fecha_inicial" {
  description = "Primera fecha proyectada (incluida), formato yyyy-MM-dd."
  type        = string
  default     = "2026-10-01"
}

variable "fecha_final" {
  description = "Última fecha proyectada (incluida), formato yyyy-MM-dd."
  type        = string
  default     = "2026-10-03"
}
