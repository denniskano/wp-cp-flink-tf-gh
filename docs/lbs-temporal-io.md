# Línea base de seguridad — Temporal Platform (Temporal.io)

Documento orientado a **Temporal Cloud** y **Temporal autogestionado (self-hosted)**, alineado a la estructura de líneas base de seguridad internas. Los requisitos técnicos citados provienen de la **documentación oficial de Temporal** ([Temporal Platform Documentation](https://docs.temporal.io/)).

Los **procedimientos, estándares de nombres, modelo de accesos corporativo y herramientas internas** del cliente (en este documento: **Banco de Crédito del Perú — BCP**) se referencian en el **[índice de enlaces internos](#índice-de-enlaces-internos-bcp--completar)**. Sustituir cada marcador de enlace por la URL definitiva (Confluence, ServiceNow, repositorio, etc.).

---

## Ficha del documento

| Campo | Valor |
|--------|--------|
| **Código / tecnología** | Temporal Platform (Temporal.io) |
| **Tipo** | Línea base de seguridad (LBS) |
| **Modalidad** | SaaS (**Temporal Cloud**) y/o **autogestionado** |
| **Complejidad** | Baja / Media / Alta (según despliegue y controles) |
| **Estado** | Borrador técnico — completar metadatos, responsables y [enlaces internos](#índice-de-enlaces-internos-bcp--completar) |

### Historial de versiones

| Versión | Fecha | Descripción |
|---------|--------|-------------|
| 0.1 | — | Creación a partir de fuentes oficiales Temporal (docs.temporal.io). |
| 0.2 | — | Índice de enlaces internos BCP y referencias cruzadas. |

---

## Consideraciones previas

### Organización (BCP) — enlazar documentación propia

- Toda administración de identidades y consolas corporativas debe alinearse a las políticas del banco (cuentas **BCPDOM**, atributo **UPN** bajo nomenclatura `alias@bcp.com.pe`, etc.). **Documento de referencia:** fila **INT-01** del [índice interno](#índice-de-enlaces-internos-bcp--completar).
- Acceso a portales cloud desde estación con salida a Internet según política; p. ej. [Azure Portal](https://portal.azure.com) para suscripciones y recursos asociados. **Guía / restricción de red interna:** **INT-02** ([índice](#índice-de-enlaces-internos-bcp--completar)).
- La configuración de esta LBS debe realizarse con cuentas que tengan **privilegios adecuados** sobre la suscripción o el tenant según el modelo de gobierno del banco. **Matriz de privilegios / aprobaciones:** **INT-03** ([índice](#índice-de-enlaces-internos-bcp--completar)).
- A los recursos aprovisionados (Namespaces, conectores, Workers en AKS, etc.) aplicar esta LBS **antes** de considerarlos productivos en **Desarrollo, Certificación o Producción**. **Ciclo de vida y gates:** **INT-04** ([índice](#índice-de-enlaces-internos-bcp--completar)).
- Nombres de recursos y etiquetas deben seguir los **estándares de Cloud** publicados en Confluence (Arquitecturas de TI). **Enlace:** **INT-05** ([índice](#índice-de-enlaces-internos-bcp--completar)).
- **Modelo de accesos** (quién puede crear API keys, certificados mTLS, roles en Temporal Cloud, SAML, Service Accounts) y su trazabilidad: **documento maestro:** **INT-06** ([índice](#índice-de-enlaces-internos-bcp--completar)).

### Plataforma Temporal (documentación oficial)

- **Temporal Cloud:** administración vía [Temporal Cloud UI](https://cloud.temporal.io/), [CLI `tcld`](https://docs.temporal.io/cloud/tcld), [Terraform Provider](https://docs.temporal.io/cloud/terraform-provider) y [Cloud Operations API](https://docs.temporal.io/ops); el acceso requiere autenticación ([API keys](https://docs.temporal.io/cloud/api-keys) u otros métodos soportados).
- **Límites operativos:** Temporal Cloud aplica límites por cuenta, Namespace y modelo de programación; revisar [System limits](https://docs.temporal.io/cloud/limits).
- **Seguridad corporativa de Temporal Technologies:** prácticas generales, certificaciones y medidas organizativas en [Temporal Trust Center](https://trust.temporal.io/) (enlazado desde [Platform security](https://docs.temporal.io/security)).

---

## Índice de enlaces internos (BCP) — completar

Sustituir `INSERTAR_URL` por el enlace definitivo. Mantener el **ID** para referencias cruzadas desde el resto del documento.

| ID | Tema | Enlace interno (completar) | Responsable sugerido (definir) |
|----|------|---------------------------|--------------------------------|
| **INT-01** | Identidad y cuentas corporativas (BCPDOM, UPN, políticas de cuenta) | [INSERTAR_URL](INSERTAR_URL) | Seguridad TI / IAM |
| **INT-02** | Red, VPN, salida a Internet y acceso a consolas / PrivateLink / PSC | [INSERTAR_URL](INSERTAR_URL) | Red / Cloud |
| **INT-03** | Gobernanza: aprobaciones, CAB, privilegios sobre suscripción o landing zone | [INSERTAR_URL](INSERTAR_URL) | Arquitectura / PMO |
| **INT-04** | Ciclo de vida: Dev / Cert / Prod, promote y criterios de “listo para producción” | [INSERTAR_URL](INSERTAR_URL) | PEVE / Agile Ops |
| **INT-05** | Estándares de nomenclatura y etiquetado (Cloud, recursos, Namespaces) | [INSERTAR_URL](INSERTAR_URL) | Arquitecturas de TI |
| **INT-06** | **Modelo de accesos Temporal:** matriz RBAC (cuenta Temporal Cloud, Namespace, Service Accounts), mapeo a roles BCP, flujo de alta/baja, rotación de API keys y certificados | [INSERTAR_URL](INSERTAR_URL) | Seguridad TI + dueño plataforma |
| **INT-07** | Procedimiento de aprovisionamiento de Namespace / cuenta Temporal (IaC, Terraform, tickets) | [INSERTAR_URL](INSERTAR_URL) | PEVE / plataforma |
| **INT-08** | Integración **SAML** con IdP corporativo (Entra ID / Okta) y checklist de atributos | [INSERTAR_URL](INSERTAR_URL) | Seguridad TI / IAM |
| **INT-09** | Custodia de secretos: API keys, certificados mTLS, integración **HashiCorp Vault** (o baúl estándar del banco) | [INSERTAR_URL](INSERTAR_URL) | SecOps / COS |
| **INT-10** | Ingesta de **logs de auditoría** Temporal Cloud a SIEM / observabilidad corporativa | [INSERTAR_URL](INSERTAR_URL) | Observability / SecOps |
| **INT-11** | Arquitectura perimetral (firewall, WAF, exposición Web UI Temporal) | [INSERTAR_URL](INSERTAR_URL) | Seguridad perimetral |
| **INT-12** | **Codec Server** y descifrado en UI: política de exposición, auth y CORS en entorno BCP | [INSERTAR_URL](INSERTAR_URL) | Squad + SecOps |
| **INT-13** | Clasificación de datos y lineamientos de datos sensibles en payloads / Event History | [INSERTAR_URL](INSERTAR_URL) | Seguridad datos / CISO |
| **INT-14** | Retención operativa, continuidad y exportación de historiales (acuerdo con negocio y cumplimiento) | [INSERTAR_URL](INSERTAR_URL) | Arquitectura / negocio |
| **INT-15** | Repositorio de automatización (RBAC, tcld, pipelines) si aplica | [INSERTAR_URL](INSERTAR_URL) | DevOps / PEVE |
| **INT-16** | Soporte: escalamiento a Temporal, gestión de incidentes internos | [INSERTAR_URL](INSERTAR_URL) | Service Desk / plataforma |

**Nota:** Los IDs **INT-01 … INT-16** se citan en las secciones siguientes. Tras completar la tabla, sustituir cada celda de enlace por un único Markdown, por ejemplo: `[Modelo de accesos Temporal](https://bcp-ti.atlassian.net/wiki/spaces/.../...)`.

---

### Cómo completar los enlaces

1. Sustituir `INSERTAR_URL` en la columna **Enlace interno** por la URL definitiva (o por una ruta relativa a documentación interna).
2. Opcional: duplicar el título del documento en el texto del enlace, p. ej. `[Matriz RBAC Temporal — BCP](URL)`.
3. Mantener la columna **Responsable sugierido** alineada al organigrama real del banco.

---

## Alcance

Esta LBS cubre la plataforma **Temporal** en sus modalidades **Cloud** y **autogestionada**, en lo relativo a:

- Arquitectura lógica (Namespaces, Workers, Clientes, UI).
- Autenticación y autorización (incl. mTLS, API keys, SAML en Cloud, plugins en self-hosted).
- Cifrado en tránsito y en reposo en **Temporal Cloud**; cifrado de cargas de aplicación (Data Converter / Payload Codec).
- Conectividad de red (TLS, conectividad privada opcional en Cloud).
- Trazabilidad y límites (APS, OPS, RPS, auditoría en Cloud).
- Integraciones (p. ej. **Temporal Nexus**), secretos y buenas prácticas de claves.
- Retención y continuidad acotadas a lo documentado por Temporal.

**Objetivo:** alinear el uso de Temporal con controles de seguridad documentados por el proveedor/plataforma y dejar explícito lo que **no aplica** o depende solo de la organización.

**Documentación del cliente (BCP):** complementar con el [índice de enlaces internos](#índice-de-enlaces-internos-bcp--completar), en particular **INT-04** (entornos), **INT-05** (nomenclatura), **INT-06** (accesos) e **INT-13** (clasificación de datos).

---

## 1. Seguridad por defecto

### 1.1 Diagrama de contexto y componentes principales

La documentación describe la **Temporal Platform** como conjunto de **Temporal Service** (servidor), **Workers** y **Clientes** ([Workers](https://docs.temporal.io/workers), [Temporal SDKs](https://docs.temporal.io/encyclopedia/temporal-sdks)).

| Componente | Descripción (fuente oficial) |
|------------|------------------------------|
| **Temporal Service / Server** | Servicio que orquesta Workflow Executions; en **Temporal Cloud** se ofrece como servicio gestionado. |
| **Worker** | Proceso que ejecuta Workflows y Activities en **su entorno de cómputo** (contenedores, VMs, etc.); **Temporal Cloud no gestiona** las aplicaciones ni los Workers ([Application and data — Code execution boundaries](https://docs.temporal.io/cloud/security)). |
| **Temporal Client** | Usado desde aplicaciones para iniciar y consultar workflows ([Temporal Client](https://docs.temporal.io/encyclopedia/temporal-sdks#temporal-client)). |
| **Namespace** | Unidad base de aislamiento lógico; en Cloud, varios Namespaces por cuenta ([Namespace isolation](https://docs.temporal.io/cloud/security)). |
| **Web UI** | Interfaz para operar y visualizar; en Cloud, autenticación de usuarios puede integrarse con SAML ([SAML authentication](https://docs.temporal.io/cloud/saml)). |

**Diagramas formales:** la documentación enlaza diagramas y guías por producto; no se reproduce aquí el diagrama — usar la documentación de arquitectura vigente en [docs.temporal.io](https://docs.temporal.io/).

**Cliente (BCP):** diagrama de contexto integrado con landing zone, identidades y Workers — **INT-07** ([índice](#índice-de-enlaces-internos-bcp--completar)); referencia de red **INT-02**.

### 1.2 Configuración inicial, aprovisionamiento y variables de entorno

| Enfoque | Contenido oficial |
|---------|-------------------|
| **Temporal Cloud** | Aprovisionamiento de Namespaces, autenticación (API keys / mTLS), conectividad y cuentas se gestiona vía UI, `tcld`, Terraform y Ops API ([Temporal Cloud](https://docs.temporal.io/cloud)). |
| **Autogestionado** | Configuración estática y dinámica del servidor, TLS, autorización; ver [Cluster & Server configuration](https://docs.temporal.io/references/configuration), [Dynamic configuration](https://docs.temporal.io/references/dynamic-configuration), [Client environment configuration](https://docs.temporal.io/references/client-environment-configuration). |

**Procedimientos internos (BCP):** runbook de aprovisionamiento, nomenclatura y automatización — **INT-07**, **INT-05**, **INT-15** ([índice](#índice-de-enlaces-internos-bcp--completar)). Roles operativos: definir en gobierno (**INT-03**).

### 1.3 Autenticación y autorización

#### Temporal Cloud

- **gRPC hacia el Namespace:** [API keys](https://docs.temporal.io/cloud/api-keys) (recomendado en muchos casos) o [mTLS con certificados de cliente](https://docs.temporal.io/cloud/certificates) emitidos por la CA configurada.
- **Usuarios en la UI:** [SAML 2.0](https://docs.temporal.io/cloud/saml) con IdP corporativo (planes Business, Enterprise, Mission Critical según [pricing](https://docs.temporal.io/cloud/pricing#base_plans)).
- **Autorización:** roles a nivel de **cuenta** y **Namespace** ([Roles and permissions](https://docs.temporal.io/cloud/manage-access/roles-and-permissions)).

**Cliente (BCP) — modelo de accesos:** matriz que relaciona roles Temporal Cloud (Global Admin, Developer, Namespace Admin, Read-only, Service Accounts) con roles y comités del banco; flujos de alta/baja/modificación; uso de API keys vs mTLS. **Documento maestro:** **INT-06**. Integración SAML con IdP: **INT-08**. Secretos y rotación: **INT-09** ([índice](#índice-de-enlaces-internos-bcp--completar)).

#### Autogestionado

- **TLS / mTLS:** cifrado entre nodos y hacia clientes; configuración en [TLS configuration](https://docs.temporal.io/references/configuration#tls); ejemplos en [samples-server (TLS)](https://github.com/temporalio/samples-server).
- **Autorización de llamadas API:** plugins **ClaimMapper** y **Authorizer**; sin configurarlos, el servidor usa **`noopAuthorizer`**, que **permite todas las peticiones** — **inseguro** para producción o redes no confiables ([Self-hosted security — Authorizer](https://docs.temporal.io/self-hosted-guide/security)).
- **SSO en UI:** OAuth mediante variables de entorno del contenedor UI ([Temporal UI — auth](https://docs.temporal.io/self-hosted-guide/security#temporal-ui)).

### 1.4 Auditorías nativas, logs y trazabilidad

#### Temporal Cloud

- Se monitorean logs de auditoría del entorno **AWS** y **todas las llamadas a la API gRPC** (SDKs, CLI, Web UI); estos logs **pueden ponerse a disposición** para ingesta en sistemas de monitoreo de seguridad del cliente ([Monitoring](https://docs.temporal.io/cloud/security)).

**Cliente (BCP):** procedimiento de solicitud, formato y destino de ingesta a SIEM u observabilidad corporativa — **INT-10** ([índice](#índice-de-enlaces-internos-bcp--completar)).

#### Autogestionado

- Depende del despliegue y de la integración con sistemas de log/métricas propios; **no hay un único “paquete de auditoría”** descrito como en Cloud — **definir según plataforma de observabilidad interna** (**INT-10**).

**Nota:** [Audit Logging](https://docs.temporal.io/self-hosted-guide/security) en self-hosted se relaciona con el modelo de plugins y despliegue; detalle operativo en la guía de seguridad autogestionada.

### 1.5 Gestión de roles, perfiles y permisos

| Plataforma | Enfoque |
|------------|---------|
| **Temporal Cloud** | RBAC: roles de cuenta (p. ej. administradores, desarrolladores, solo lectura) y permisos a nivel Namespace ([Roles and permissions](https://docs.temporal.io/cloud/manage-access/roles-and-permissions)). |
| **Autogestionado** | Mapeo de claims JWT a roles Temporal (`read`, `write`, `worker`, `admin`) mediante **ClaimMapper** y decisiones en **Authorizer** ([Authorization](https://docs.temporal.io/self-hosted-guide/security)). |

**Cliente (BCP):** perfilamiento y revisiones periódicas de acceso según política interna; enlazar a **INT-06** y, si existe, repositorio de automatización **INT-15** ([índice](#índice-de-enlaces-internos-bcp--completar)).

### 1.6 Reportes para gestión de usuarios

- **Temporal Cloud:** gestión de usuarios e identidades vía UI y herramientas de cuenta; **no se documenta** un “motor de reportes” equivalente a un SIEM de RRHH — **no aplica** como requisito de producto en la documentación consultada.
- **Cliente (BCP):** reportes o extractos para auditoría de identidades / cumplimiento — definir procedimiento y herramienta interna (**INT-06**, **INT-16** si aplica) ([índice](#índice-de-enlaces-internos-bcp--completar)).

### 1.7 Custodia y deshabilitación de usuarios por defecto o con privilegios elevados

- **Temporal Cloud:** el modelo de identidad y cuentas de servicio está descrito en [Service Accounts](https://docs.temporal.io/cloud/service-accounts) y [API keys](https://docs.temporal.io/cloud/api-keys); rotación y deshabilitación de claves en la documentación.
- **Autogestionado:** riesgo crítico si no se configura **Authorizer** + **ClaimMapper**; cualquier cliente con acceso de red al Frontend podría invocar APIs ([advertencia oficial](https://docs.temporal.io/self-hosted-guide/security)).

**Contraseñas de usuario por defecto de un producto genérico:** **no aplica** al modelo de Temporal Cloud (autenticación IdP / API keys / certificados según configuración).

**Cliente (BCP):** custodia de cuentas de break-glass o administración exclusiva del banco — **INT-06**, **INT-09** ([índice](#índice-de-enlaces-internos-bcp--completar)).

### 1.8 Identificación y aseguramiento de archivos y rutas de configuración

- Relevante en **autogestionado** (archivos YAML, certificados, variables de entorno de UI y servidor) según [Configuration](https://docs.temporal.io/references/configuration) y guías de despliegue.
- En **Temporal Cloud**, la configuración del plano de control y datos del servicio **no está expuesta** como archivos en el lado del cliente — **parcialmente no aplica** al modelo SaaS.

### 1.9 Encriptación de contraseñas por defecto y delegación a equipos de secretos

- **Credenciales sensibles:** API keys, certificados mTLS y material criptográfico deben gestionarse con prácticas de secretos (KMS, vault corporativo, etc.); Temporal documenta [Key management](https://docs.temporal.io/key-management) y buenas prácticas para claves de cifrado de Payloads.

**Cliente (BCP):** baúl de secretos estándar, rotación y responsable (p. ej. COS / SecOps) — **INT-09** ([índice](#índice-de-enlaces-internos-bcp--completar)).

### 1.10 Vulnerabilidades, pruebas y actualizaciones

#### Temporal Cloud

- **Cifrado en tránsito:** TLS **1.3** en todas las conexiones ([Encryption](https://docs.temporal.io/cloud/security)).
- **Cifrado en reposo:** almacenamiento en Elasticsearch (visibilidad) y capa de persistencia principal con **AES-256-GCM** ([Encryption](https://docs.temporal.io/cloud/security)).
- **Pruebas:** pentest de terceros anual (alcance documentado) y pruebas adicionales puntuales ([Testing](https://docs.temporal.io/cloud/security)).
- **Acceso interno de Temporal** a producción: restringido, MFA, SSO, sin cuentas compartidas, revisión de accesos ([Internal Temporal access](https://docs.temporal.io/cloud/security)).
- **Cumplimiento:** Temporal indica certificación **SOC 2 Type 2** y alineación con **GDPR** y **HIPAA**; auditorías bajo solicitud ([Compliance](https://docs.temporal.io/cloud/security)).

#### Autogestionado

- Parcheo y hardening del SO, imagen de contenedor y dependencias **corresponden al operador**; Temporal publica el **servidor open source** y guías de seguridad ([Self-hosted security](https://docs.temporal.io/self-hosted-guide/security)).

---

## 2. Seguridad por capas

### 2.1 Arquitectura de red

- **Temporal Cloud:** conectividad desde Internet y opción de **conectividad privada** ([Private network connectivity](https://docs.temporal.io/cloud/connectivity)) vía **AWS PrivateLink** o **GCP Private Service Connect**; reglas de conectividad por Namespace ([Connectivity rules](https://docs.temporal.io/cloud/connectivity#connectivity-rules)) — en *public preview* según la documentación.
- **Plano de control:** hostnames documentados (`saas-api.tmprl.cloud`, `web.onboarding.tmprl.cloud`, etc.); PrivateLink al plano de control en AWS documentado ([Control plane connectivity](https://docs.temporal.io/cloud/connectivity#control-plane-connectivity)).

### 2.2 Seguridad perimetral

- **Temporal Cloud:** limitación de rutas de acceso mediante **connectivity rules** (públicas/privadas) y autenticación obligatoria con API keys o mTLS ([Connectivity](https://docs.temporal.io/cloud/connectivity)).
- **Web UI y reglas:** la UI de Temporal Cloud **no queda sujeta** a la aplicación de reglas de conectividad del Namespace en el comportamiento descrito — la UI puede seguir siendo accesible por Internet ([Web UI Connectivity](https://docs.temporal.io/cloud/connectivity#web-ui-connectivity)).

**Cliente (BCP):** diseño perimetral (firewall, segmentación, exposición de UI Temporal), alineado a política de red — **INT-11**; conectividad privada (PrivateLink / PSC) y aprobaciones — **INT-02** ([índice](#índice-de-enlaces-internos-bcp--completar)).

- **WAF estándar del banco frente al producto Temporal como servicio:** **no aplica** como requisito documentado por Temporal — valorar según **INT-11**.

### 2.3 Aislamiento

- **Namespaces:** aislamiento lógico por Namespace; sin compartir datos entre Namespaces salvo mecanismos explícitos (**Temporal Nexus**) ([Namespace isolation](https://docs.temporal.io/cloud/security)).
- **Multi-región / datos:** Namespaces no comparten procesamiento ni almacenamiento **entre fronteras regionales** en el sentido descrito en la documentación de segregación lógica ([Logical segregation](https://docs.temporal.io/cloud/security)).

### 2.4 Protocolos, servicios y formatos

- **TLS:** TLS 1.3 en Cloud; mTLS como **método de autenticación**, no sustituto del cifrado ([TLS vs mTLS](https://docs.temporal.io/cloud/security)).
- **Self-hosted:** TLS/mTLS configurable; deshabilitar exposición innecesaria y seguir [Self-hosted security](https://docs.temporal.io/self-hosted-guide/security).
- **Payloads:** serialización mediante Data Converter; formatos habituales en documentación ([Data conversion](https://docs.temporal.io/dataconversion)); cifrado opcional vía **Payload Codec** ([Data encryption](https://docs.temporal.io/production-deployment/data-encryption)).

### 2.5 Aseguramiento del canal

- **Temporal Cloud:** TLS 1.3 en todas las conexiones ([Encryption](https://docs.temporal.io/cloud/security)).
- **Self-hosted:** configuración de `frontend` e `internode` TLS en [TLS configuration](https://docs.temporal.io/references/configuration#tls).

### 2.6 Custodia de certificados y claves

| Tema | Referencia oficial |
|------|---------------------|
| **mTLS en Cloud** | [Certificates](https://docs.temporal.io/cloud/certificates); límites por Namespace ([Certificates limits](https://docs.temporal.io/cloud/limits#certificates)). |
| **API keys** | [API keys](https://docs.temporal.io/cloud/api-keys); rotación y buenas prácticas en la misma página. |
| **Claves de cifrado de datos de aplicación** | [Key management](https://docs.temporal.io/key-management); [Data encryption](https://docs.temporal.io/production-deployment/data-encryption). |

**Cliente (BCP):** procedimiento de emisión/renovación de certificados mTLS, almacenamiento en Vault y responsables — **INT-09**; gestión de API keys acorde a **INT-06** ([índice](#índice-de-enlaces-internos-bcp--completar)).

### 2.7 Registro en WAF estándar

**No aplica** como ítem específico de la plataforma Temporal en la documentación oficial. **Cliente (BCP):** si el perímetro lo exige, enlazar política — **INT-11** ([índice](#índice-de-enlaces-internos-bcp--completar)).

### 2.8 DNS y nombres de host

- **Temporal Cloud:** uso de endpoints y nombres provistos (`*.tmprl.cloud`, `*.api.temporal.io` según modos documentados en [Namespaces](https://docs.temporal.io/cloud/namespaces) y [Connectivity](https://docs.temporal.io/cloud/connectivity)); DNS privado recomendado para PrivateLink/PSC.
- **Registro de dominio propio del banco** (p. ej. Codec Server, callbacks IdP): **definir** en arquitectura y DNS interno — **INT-02**, **INT-12** ([índice](#índice-de-enlaces-internos-bcp--completar)).

---

## 3. Seguridad por diseño

### 3.1 Componentes e integración con controles

Resumen alineado a [Security model — Temporal Cloud](https://docs.temporal.io/cloud/security):

- Autenticación (API keys, mTLS, SAML para usuarios UI).
- Cifrado en tránsito (TLS 1.3) y en reposo (AES-256-GCM en componentes indicados).
- Aislamiento por Namespace y límites de tasa (APS, OPS, RPS).
- Opcional: cifrado de payload en el cliente (Data Converter) para que el servicio no pueda leer datos sensibles.

### 3.2 Integración con aplicaciones y sistemas de la organización

- Workers y clientes se ejecutan en **entorno controlado por la organización** ([Code execution boundaries](https://docs.temporal.io/cloud/security)).
- Integración con APIs internas, colas y bases mediante **Activities**, **Child Workflows**, **Signals**, **Queries**, etc., según modelos en [docs.temporal.io](https://docs.temporal.io/).

### 3.3 Integraciones entre sistemas (incl. Nexus)

- **Temporal Nexus:** comunicación controlada entre Namespaces; políticas de allowlist, autenticación de Workers con mTLS o API key, tráfico cifrado en Cloud ([Nexus Security](https://docs.temporal.io/nexus/security)).
- **Data Converter** en operaciones Nexus: mismo mecanismo que en Workflows ([Payload encryption](https://docs.temporal.io/nexus/security#payload-encryption-and-data-converter)).

### 3.4 Controles adicionales sobre componentes estándar

- Extensibilidad en self-hosted (**Authorizer**, **ClaimMapper**, Data Converter, Codec Server) — ver secciones anteriores.
- **No aplica** un catálogo único adicional “cerrado” en documentación más allá de estas extensiones.

### 3.5 Secretos e intercambio seguro; baúl de secretos

- Temporal recomienda **KMS** y prácticas de gestión de claves; ejemplo de integración con **HashiCorp Vault** citado en [Key management — Using Vault](https://docs.temporal.io/key-management#using-vault-for-key-management) (referencia a repositorio de ejemplo).

**Cliente (BCP):** baúl estándar, estándares de intercambio de secretos y uso en Workers / Codec Server — **INT-09**, **INT-12** ([índice](#índice-de-enlaces-internos-bcp--completar)).

### 3.6 Disponibilidad y continuidad

- **Temporal Cloud [High Availability](https://docs.temporal.io/cloud/high-availability):** documentación específica de regiones y failover para Namespaces elegibles.
- **Acuerdos de nivel de servicio y arquitectura multi-región:** revisar documentación de producto y contrato; detalle técnico en [docs.temporal.io/cloud](https://docs.temporal.io/cloud).

### 3.7 “Backups” y retención

- **No** se documenta un “backup tradicional” descargable del historial como copia de ficheros genérica en los mismos términos que una base de datos clásica.
- **Retención de Event History:** período de retención por Namespace (por defecto **30 días** en Cloud, configurable **1–90 días**) ([Default Retention Period](https://docs.temporal.io/cloud/limits#default-retention-period)).
- Continuidad y estrategias de exportación/archivado de historiales o datos de negocio: **responsabilidad de diseño de la solución** y políticas internas, más allá del texto citado.

**Cliente (BCP):** criterios de retención, continuidad y acuerdos con negocio/cumplimiento — **INT-14**; escalamiento ante incidentes — **INT-16** ([índice](#índice-de-enlaces-internos-bcp--completar)).

### 3.8 Gobierno y ciclo de vida

- **Temporal Cloud:** actualizaciones operadas por Temporal; cliente gestiona configuración de Namespace, conectividad, identidades y límites según documentación.
- **Self-hosted:** el operador gestiona versiones del [Temporal Server](https://docs.temporal.io/self-hosted-guide) y dependencias.

---

## 4. Seguridad del dato y en el desarrollo

### 4.1 Flujo de información y clasificación de datos

- La **clasificación de datos** (público, interno, secreto, etc.) es **política de la organización** — **no aplica** como tabla en documentación Temporal.
- Flujo técnico: datos serializados en **Payloads**; opcionalmente cifrados antes de persistir en el servidor ([Data encryption](https://docs.temporal.io/production-deployment/data-encryption)).

**Cliente (BCP):** taxonomía de datos, qué puede viajar en Payloads y requisitos de cifrado con Payload Codec — **INT-13** ([índice](#índice-de-enlaces-internos-bcp--completar)).

### 4.2 Gobierno y ciclo de vida del dato

**No aplica** un marco único de gobierno de datos corporativo en la documentación de producto; **Cliente (BCP):** alinear a políticas de gobierno de datos del banco — **INT-13** ([índice](#índice-de-enlaces-internos-bcp--completar)). Capacidades de producto: visibilidad, búsqueda en [docs.temporal.io](https://docs.temporal.io/).

### 4.3 Normativas y cumplimiento

- Referencia en [Compliance — Temporal Cloud](https://docs.temporal.io/cloud/security): SOC 2 Type 2, GDPR, HIPAA (detalle legal y auditorías según contrato y [Trust Center](https://trust.temporal.io/)).

### 4.4 Repositorio de datos y metadatos

- Datos persistidos en el servicio Temporal (historial de eventos, visibilidad) están sujetos al modelo de **Temporal Cloud** o al despliegue autogestionado; **cifrado en reposo en Cloud** descrito en [Encryption](https://docs.temporal.io/cloud/security).
- **Data store interno del banco** como “repositorio oficial” de metadatos Temporal: **no aplica** salvo arquitectura híbrida definida por la organización.

### 4.5 Cifrado en tránsito y en reposo

| Ámbito | Contenido oficial |
|--------|-------------------|
| **En tránsito (Cloud)** | TLS **1.3** ([Encryption](https://docs.temporal.io/cloud/security)). |
| **En reposo (Cloud)** | **AES-256-GCM** en almacenamientos indicados (Elasticsearch y persistencia principal) ([Encryption](https://docs.temporal.io/cloud/security)). |
| **Datos de aplicación** | Cifrado **opcional** en cliente con **Payload Codec** / Data Converter; Temporal Cloud **no puede descifrar** si se implementa correctamente ([Data Converter](https://docs.temporal.io/dataconversion), [Cloud security](https://docs.temporal.io/cloud/security)). |
| **Visualización en UI** | **Codec Server** en entorno controlado; consideraciones de seguridad en [Codec Server](https://docs.temporal.io/production-deployment/data-encryption#codec-server-setup) y [Codec Server concept](https://docs.temporal.io/codec-server). |

**Cliente (BCP):** política de uso de Codec Server, HTTPS, CORS y validación de tokens JWT desde la UI Cloud — **INT-12** ([índice](#índice-de-enlaces-internos-bcp--completar)).

### 4.6 Buenas prácticas de desarrollo seguro

- Manejo de **Payloads** grandes ([BlobSizeLimitError](https://docs.temporal.io/troubleshooting/blob-size-limit-error)), límites de historial y señales ([Workflow limits](https://docs.temporal.io/workflow-execution/limits)).
- **Throttling:** manejo de `ResourceExhausted` y métricas ([Throttling behavior](https://docs.temporal.io/cloud/limits#throttling-behavior)).
- SDK y patrones en [Develop](https://docs.temporal.io/develop).

### 4.7 Integración con metodología (Agile, etc.)

**No aplica** en documentación Temporal como requisito de seguridad. **Cliente (BCP):** SDLC y controles en pipelines — enlazar estándar interno si existe (**INT-04**, **INT-07**) ([índice](#índice-de-enlaces-internos-bcp--completar)).

---

## 5. Referencias (fuentes oficiales Temporal)

| Recurso | URL |
|---------|-----|
| Portal de seguridad de la plataforma | https://docs.temporal.io/security |
| Seguridad en Temporal Cloud | https://docs.temporal.io/cloud/security |
| Seguridad autogestionada | https://docs.temporal.io/self-hosted-guide/security |
| Conectividad (PrivateLink, PSC, reglas) | https://docs.temporal.io/cloud/connectivity |
| API keys | https://docs.temporal.io/cloud/api-keys |
| Certificados mTLS | https://docs.temporal.io/cloud/certificates |
| SAML | https://docs.temporal.io/cloud/saml |
| Límites del sistema | https://docs.temporal.io/cloud/limits |
| Cifrado de datos (Payload Codec, Codec Server) | https://docs.temporal.io/production-deployment/data-encryption |
| Conversión de datos | https://docs.temporal.io/dataconversion |
| Gestión de claves | https://docs.temporal.io/key-management |
| Seguridad en Nexus | https://docs.temporal.io/nexus/security |
| Roles y permisos | https://docs.temporal.io/cloud/manage-access/roles-and-permissions |
| Centro de confianza (Temporal Technologies) | https://trust.temporal.io/ |
| Whitepaper de seguridad en la nube (enlazado desde docs) | https://temporal.io/pages/cloud-security-white-paper |

---

## 6. Referencias internas del cliente (BCP)

Documentación y procedimientos propios del banco: ver **[índice de enlaces internos — completar](#índice-de-enlaces-internos-bcp--completar)** (tabla **INT-01** a **INT-16**). No incluir aquí URLs hasta que estén aprobadas para publicación.

---

## 7. Glosario (basado en documentación oficial)

| Término | Definición breve |
|---------|------------------|
| **Temporal Platform** | Plataforma de orquestación de workflows durable y distribuidos ([Temporal](https://docs.temporal.io/temporal)). |
| **Temporal Cloud** | Oferta SaaS de Temporal ([Temporal Cloud](https://docs.temporal.io/cloud)). |
| **Namespace** | Unidad de aislamiento lógico para cargas de trabajo ([Namespaces](https://docs.temporal.io/namespaces)). |
| **Workflow** | Ejecución durable de lógica de orquestación ([Workflows](https://docs.temporal.io/workflows)). |
| **Worker** | Proceso que ejecuta código de workflow y activity ([Workers](https://docs.temporal.io/workers)). |
| **Task Queue** | Cola desde la que los Workers obtienen tareas ([Task Queues](https://docs.temporal.io/task-queue)). |
| **Data Converter / Payload Codec** | Cadena de serialización y opcionalmente cifrado de Payloads ([Data conversion](https://docs.temporal.io/dataconversion)). |
| **Codec Server** | Servicio HTTP que decodifica Payloads para UI/CLI sin almacenar claves en Temporal ([Codec Server](https://docs.temporal.io/codec-server)). |
| **mTLS** | Autenticación mutua con certificados X.509; en Cloud complementa TLS ([Certificates](https://docs.temporal.io/cloud/certificates)). |
| **API key** | Token de identidad para autenticación en Cloud ([API keys](https://docs.temporal.io/cloud/api-keys)). |
| **Temporal Nexus** | Comunicación entre Namespaces con controles de acceso ([Nexus](https://docs.temporal.io/nexus)). |
| **APS / OPS / RPS** | Límites de acciones, operaciones y solicitudes por segundo ([Limits](https://docs.temporal.io/cloud/limits)). |

---

*Documento alineado a LBS tipo Confluent: requisitos de producto según [docs.temporal.io](https://docs.temporal.io/); obligaciones y enlaces del cliente (BCP) en el [índice interno](#índice-de-enlaces-internos-bcp--completar).*
