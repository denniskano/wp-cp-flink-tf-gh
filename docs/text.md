Quedó la versión 1.0 final, lista para aprobación. El marco ya no se reescribe: lo que falta es ejecutar la fase 0, no otra redacción.

Plan: docs/plan-retiro-temporal-cloud-insolvencia.md
Resumen de decisión: docs/plan-retiro-temporal-cloud-resumen-aprobacion.md
Diagrama: docs/assets/arquitectura-temporal-self-hosted-aks.png (está en el §04 y en el resumen)

Qué se cerró en esta pasada
Control documental (código PEVE-EXIT-TEMPORAL-CLOUD-01, dueño, revisores, vigencia).
§04 arquitectura objetivo con el diagrama, Mermaid editable y decisiones de diseño: AKS PEVE para el control plane (Frontend, History, Matching, Worker Service), workers en el AKS de las apps, PostgreSQL, visibilidad, Blob para archival/export, Key Vault, Monitor, Private Link, dos footprints (no-prod y prod).
Transición dual-client y failover estresado, también en diagrama.
§13 comunicación, §14 hoja de ruta fase 0 (pasos 0.1–0.10), §15 glosario.
Anexo F con F13 (arquitectura conformada).
Cómo se lee la propuesta Self-Hosted
Tres planos, Frontend sin internet público:

Aplicación — APOQ/NREM y workers que ya existen; el core es la fuente de verdad.
Control plane PEVE — Temporal Server en AKS dedicado.
Azure privada — persistencia, visibilidad, historiales, secretos, monitoreo.
PEVE opera el cluster. Las aplicaciones solo cambian endpoint. No hay réplica Cloud → Self-Hosted.

Qué no es “versión 2 del Word”
El Anexo G sigue en blanco a propósito (RTO, nombres reales de workflow, sizing, comité). Eso se llena al ejecutar 0.1–0.10. Cuando el Anexo F esté en sí, el Banco tiene capacidad de salida, no solo el plan.

El pedido a la instancia, sin cambiar: aprobar 1.0, mandatar fase 0, congelar nuevos *-prod en Cloud y reservar el cutover.