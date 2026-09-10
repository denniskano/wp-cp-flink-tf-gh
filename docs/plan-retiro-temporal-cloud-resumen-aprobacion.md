# Retiro de Temporal Cloud ante insolvencia — resumen para aprobación

**BCP · PEVE · Versión 1.0 final · Uso interno**  
Documento de decisión. El detalle está en `plan-retiro-temporal-cloud-insolvencia.md`.

![Arquitectura Temporal Self-Hosted en Azure AKS](assets/arquitectura-temporal-self-hosted-aks.png)

El destino no es otro SaaS: control plane Temporal en AKS de PEVE (Frontend, History, Matching, Worker Service), persistencia y visibilidad en Azure privada, workers de APOQ/NREM en el AKS que ya tienen. Frontend sin internet público.

---

## Decisión que se pide

Aprobar el plan de retiro preventivo de Temporal Cloud y mandatar la **fase 0** (standby Self-Hosted en Azure AKS) como control del riesgo de going-concern de Temporal Technologies Inc.

No se pide, en este acto, ejecutar el cutover productivo de APOQ ni NREM.

---

## Por qué existe el plan

Temporal Cloud orquesta y persiste el estado de workflows del Banco. Es un SaaS significativo: si Temporal Technologies Inc. no puede seguir operándolo, el control plane desaparece. El P&L en rojo del proveedor es **vigilancia**, no prueba de quiebra. El riesgo que se trata es **cese de capacidad de operar Cloud**.

El Banco ya corre los workers en su AKS. Lo que no controla es el SaaS. La alternativa no es otro producto: es el **mismo motor Temporal, open source, hospedado por el Banco**.

---

## Qué se cubre y qué no

| Cubierto | No cubierto |
|---|---|
| Insolvencia, liquidación, cese, pérdida material de Cloud | Incidente corto de Cloud (eso es BCM/DR) |
| APOQ y NREM en producción | Otras empresas del grupo |
| Apps en dev/cert: CPCA, CPCC, APTI/TUPI, CDPT, SRCR, LBCL, CPCR | Cambios funcionales ajenos al retiro |
| Destino: Temporal Self-Hosted en Azure AKS | Otro SaaS de orquestación, salvo nueva aprobación |

---

## Tres desenlaces (un solo playbook, dos modos)

| Si el proveedor… | Cloud | El Banco |
|---|---|---|
| Se reorganiza | Suele seguir unas semanas | Cutover por ambientes; drain de lo corto |
| Se vende | Sigue; cambia el dueño | Misma ruta técnica |
| Se liquida o se apaga | Puede quedar oscuro | Failover. Se reconstruye desde el core, no desde el historial vivo |

En liquidación el contrato no salva: no hay export, no hay tickets, no hay reversa. Por eso la fase 0 es el control, no la cláusula.

---

## Qué no puede pasar

APOQ mueve débito, crédito y compensación. NREM emite y recibe remesas. **Un workflow o un schedule no puede estar activo en Cloud y en Self-Hosted a la vez.** Si hay duda sobre un lado ya ejecutado, va a cola de excepción: no se automatiza el segundo lado.

Temporal no es el libro mayor. Si Cloud muere, el RPO es el estado de negocio (core, outbox, tracking de remesas), no el event history del SaaS.

---

## Gobierno

PEVE gobierna y entrega la receta. Los equipos de aplicación ejecutan. El PO concilia y acepta. Arquitectura, Seguridad, Continuidad, RNF, Legal y Compras emiten sus conformidades. La instancia aprobadora declara watch, activación, excepciones, producción y cierre.

**Watch** = congelar lo nuevo en Cloud y terminar la fase 0.  
**Activación** = cutover. La dispara un aviso formal, un going-concern acreditado o Cloud inutilizable. No la dispara el EBITDA del vendor.

---

## Secuencia

Preparar Self-Hosted ahora → activar cuando corresponda → dev → cert → producción (APOQ y NREM en paralelo, cada una con sus evidencias) → revocar Cloud → cerrar expediente.

Ninguna app del inventario nace en producción sobre Temporal Cloud.

---

## Condición para decir que el plan sirve

Fase 0 completa (Anexo F): arquitectura §04 conformada; cluster Self-Hosted con restore ensayado; namespaces APOQ/NREM; dual-client con reversa; historiales Cloud copiados a Blob del Banco; matriz de workflows firmada por los PO; RTO/RPO vigentes; ejercicio técnico y tabletop “Cloud no responde”.

Hasta entonces el residual es: *el Banco tiene un escrito, no una salida*.

---

## Aprobaciones

| Pedido | Efecto |
|---|---|
| Aprobar este plan como versión vigente | PEVE lo mantiene; RNF o Auditoría lo revisa anualmente |
| Mandatar fase 0 | PEVE + Arquitectura + Seguridad + APOQ + NREM ejecutan el Anexo F |
| Congelar nuevos `*-prod` en Temporal Cloud | Las apps en cert solo producen sobre Self-Hosted |
| Reservar activación a la instancia | Nadie corta Cloud ni hace failover productivo sin acta |

Arquitectura (§04), hoja de ruta fase 0 (§14), día D (Anexo E) y pendientes nominativos (Anexo G): documento completo.
