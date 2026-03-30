# Hardening de Seguridad para Temporal Cloud

Alcance **exclusivo Temporal Cloud** (SaaS). Los requisitos técnicos del proveedor provienen de [docs.temporal.io](https://docs.temporal.io/cloud). **No cubre** despliegue autogestionado (self-hosted).

---

## Ficha del documento


| Campo               | Valor                                              |
| ------------------- | -------------------------------------------------- |
| **Cod. Tecnología** | Temporal Cloud                                     |
| **Tipo**            | Hardening / Línea base de seguridad (LBS)          |
| **Plataforma**      | SaaS (Temporal Cloud)                              |
| **Complejidad**     | Baja / Media / Alta                                |
| **Estado**          | Borrador técnico                                   |


### Historial de versiones


| Fecha creación / actualización | Versión | Descripción                                                                 | Sección impactada | Desarrollado por | Revisado por | Aprobado por | Fecha publicación | Tiempo de adecuación / ejecución de LBS |
| ------------------------------ | ------- | --------------------------------------------------------------------------- | ----------------- | ---------------- | ------------ | ------------ | ----------------- | --------------------------------------- |
| —                              | 0.1     | Creación a partir de documentación oficial Temporal                         | Creación          | —                | —            | —            | —                 | —                                       |
| —                              | 0.2     | Acotación solo a Temporal Cloud                                             | Alcance           | —                | —            | —            | —                 | —                                       |
| —                              | 0.3     | Formato alineado a hardening Confluent Cloud (`temporal-hardening.md`)      | Documento completo | —               | —            | —            | —                 | —                                       |


---

## Consideraciones previas

- Toda la administración de identidades corporativas debe alinearse a las políticas del banco: cuentas **BCPDOM**, atributo **UPN** bajo nomenclatura `alias@bcp.com.pe`.
- Acceso a consolas cloud desde estación con salida a Internet según política; p. ej. [Azure Portal](https://portal.azure.com) para suscripciones asociadas.
- Realizar la configuración con cuentas que tengan **privilegios adecuados** sobre la suscripción o el tenant según el modelo de gobierno del banco.
- A **Namespaces**, cuenta Temporal Cloud, Workers (p. ej. en AKS) y recursos relacionados aplicar esta LBS **antes** de considerarlos productivos en **Desarrollo, Certificación o Producción**.
- Nombres de recursos y etiquetas según **estándares de Cloud** en Confluence — *Arquitecturas de TI* ([enlace Confluence](https://bcp-ti.atlassian.net/wiki)).
- Administración de **Temporal Cloud** vía [Temporal Cloud UI](https://cloud.temporal.io/), [CLI `tcld`](https://docs.temporal.io/cloud/tcld), [Terraform Provider](https://docs.temporal.io/cloud/terraform-provider) y [Cloud Operations API](https://docs.temporal.io/ops); autenticación con [API keys](https://docs.temporal.io/cloud/api-keys) u otros métodos soportados. Límites: [System limits](https://docs.temporal.io/cloud/limits). Prácticas y certificaciones del proveedor: [Temporal Trust Center](https://trust.temporal.io/).

---

## Alcance

El alcance de la **Línea Base de Seguridad (LBS)** para **Temporal Cloud (SaaS)** incluye la implementación y gestión segura de la plataforma en los entornos de **desarrollo, certificación y producción**, abarcando:

- Configuración inicial y aprovisionamiento (Namespaces, conectividad, identidades)
- Autenticación y autorización (API keys, mTLS, SAML, RBAC cuenta/Namespace)
- Auditorías y trazabilidad según oferta Cloud
- Gestión de roles y permisos
- Seguridad perimetral y conectividad (incl. PrivateLink / PSC cuando aplique)
- Aislamiento lógico (Namespaces, Nexus)
- Protocolos y formatos (TLS 1.3, payloads, Data Converter)
- Aseguramiento del canal
- Custodia de certificados y API keys del lado cliente
- Integración con sistemas del banco (Workers, clientes, Codecs)
- Cifrado en tránsito y en reposo en Cloud; cifrado opcional de payload (Payload Codec / Codec Server)
- Disponibilidad, retención de historial y continuidad acotadas a documentación del producto
- Buenas prácticas de desarrollo seguro (límites, throttling)

**Objetivo:** alinear el uso de Temporal Cloud con controles documentados por el proveedor y con políticas internas del banco (secretos, red, gobierno de datos).

---

## 1. Seguridad por defecto

### 1.1 Diagrama de contexto de la plataforma

La **Temporal Platform** se describe como **Temporal Service** (servidor gestionado en Cloud), **Workers** y **Clientes** ([Workers](https://docs.temporal.io/workers), [Temporal SDKs](https://docs.temporal.io/encyclopedia/temporal-sdks)). El diagrama de contexto integrado con landing zone, identidades y despliegue de Workers debe constar en la **documentación de arquitectura interna** del banco.

#### Componentes principales


| Componente                    | Descripción                                                                                                                                      |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Temporal Service / Server** | Orquesta ejecuciones de workflow; en Temporal Cloud es **servicio gestionado**.                                                                |
| **Worker**                    | Ejecuta Workflows y Activities en **entorno del cliente**; Temporal Cloud **no** opera la aplicación ni los Workers ([Code execution boundaries](https://docs.temporal.io/cloud/security)). |
| **Temporal Client**           | Inicia y consulta workflows desde aplicaciones ([Temporal Client](https://docs.temporal.io/encyclopedia/temporal-sdks#temporal-client)).        |
| **Namespace**               | Unidad de aislamiento lógico; varios Namespaces por cuenta ([Namespace isolation](https://docs.temporal.io/cloud/security)).                     |
| **Web UI**                   | Operación y visualización; usuarios pueden autenticarse vía [SAML 2.0](https://docs.temporal.io/cloud/saml) con IdP corporativo.                 |


Diagramas formales: [docs.temporal.io](https://docs.temporal.io/).

### 1.2 Configuración inicial o variables de entorno e instalación (rol responsable)

Esta sección cubre (**a**) la **primera implantación** cuando se contrata el servicio o se abre la cuenta Temporal Cloud; (**b**) la **configuración inicial** que incluye el **aprovisionamiento de Namespaces** cada vez que se crea un entorno lógico nuevo (nombre, región, retención, auth, opciones de Codec, permisos).

El recorrido “de cero” en documentación oficial: alta de cuenta → Namespace → clientes/Workers → primera ejecución → equipo ([Get started with Temporal Cloud](https://docs.temporal.io/cloud/get-started)). El detalle de **creación y gestión de Namespaces** está en [Namespaces](https://docs.temporal.io/cloud/namespaces). Herramientas: **Web UI**, [`tcld`](https://docs.temporal.io/cloud/tcld), [Terraform Provider](https://docs.temporal.io/cloud/terraform-provider) y [Cloud Operations API](https://docs.temporal.io/ops).

#### Aprovisionamiento de Namespaces (configuración inicial del recurso)

Un **Namespace** aísla cargas de trabajo en Temporal Cloud (seguridad, límites, endpoints gRPC). **Aprovisionar** un Namespace es el paso principal de configuración **del lado del servicio Temporal** para cada entorno (p. ej. Dev / Cert / Prod o por dominio).

**Roles**

- Puede crear un Namespace un usuario con rol de cuenta **Developer**, **Account Owner** o **Global Admin** ([account-level roles](https://docs.temporal.io/cloud/manage-access/roles-and-permissions#account-level-roles)).  
- Quien **crea** el Namespace obtiene automáticamente [**Namespace Admin**](https://docs.temporal.io/cloud/manage-access/roles-and-permissions#namespace-level-permissions) en ese Namespace.

**Cupos**

- Límite inicial típico: **10 Namespaces** por cuenta; el proveedor puede **incrementar automáticamente** el cupo al usarlos, hasta **100**. Más capacidad: [ticket de soporte](https://docs.temporal.io/cloud/support#support-ticket).

**Datos a acordar antes del alta** ([Information needed](https://docs.temporal.io/cloud/namespaces#information-needed-to-create-a-namespace))

| Dato | Notas |
| ---- | ----- |
| **Nombre** | Lo define el cliente; **no es modificable** tras crear el Namespace. Reglas oficiales: longitud 2–39, minúsculas, letras, números y `-`; sin guiones consecutivos ([Cloud Namespace Name](https://docs.temporal.io/cloud/namespaces#temporal-cloud-namespace-name)). |
| **Proveedor cloud y región** | Selección en el alta del Namespace. |
| **Retención de historial** | **1–90 días** para workflows **cerrados**; ajuste posterior vía [Temporal Support](https://docs.temporal.io/cloud/support#support-ticket). |
| **Auth al Namespace** | [API keys](https://docs.temporal.io/cloud/api-keys) (recomendación habitual) o [mTLS](https://docs.temporal.io/cloud/certificates) + [CA del Namespace](https://docs.temporal.io/cloud/certificates#certificate-requirements). |
| **Codec Server (opcional)** | URL HTTPS y opciones de token/CORS para ver payloads en UI ([data encryption](https://docs.temporal.io/production-deployment/data-encryption)). |
| **Usuarios / permisos** | [Namespace-level permissions](https://docs.temporal.io/cloud/manage-access/roles-and-permissions#namespace-level-permissions); se pueden completar después en **Edit**. |

**Identificadores y conexión**

- **Namespace Id:** `<nombre>.<account-id>` ([Cloud Namespace Id](https://docs.temporal.io/cloud/namespaces#temporal-cloud-namespace-id)); el **Account ID** aparece en la UI (menú de cuenta) o vía `tcld`.  
- **Endpoint gRPC:** en la ficha del Namespace, **Connect** ([gRPC endpoint](https://docs.temporal.io/cloud/namespaces#temporal-cloud-grpc-endpoint)). Suelen usarse el endpoint **por Namespace** (`*.tmprl.cloud:7233`, recomendado e idóneo con [HA](https://docs.temporal.io/cloud/high-availability)) o el **regional** (`*.api.temporal.io:7233`) según diseño ([acceso al Namespace](https://docs.temporal.io/cloud/namespaces#access-namespaces)).  
- **URL Web UI:** `https://cloud.temporal.io/namespaces/<namespace-id>`.

**Alta por Web UI (resumen)** ([Create Namespace](https://docs.temporal.io/cloud/namespaces#create-a-namespace-using-temporal-cloud-ui))

Namespaces → **Create Namespace** → Nombre → Proveedor y región → Retención (1–90 días) → API keys o mTLS (+ CA si aplica) → Opcional Codec Server → **Create Namespace**.

**Automatización**

- `tcld`: [`namespace list` / `get`](https://docs.temporal.io/cloud/tcld/namespace/#list), [certificados](https://docs.temporal.io/cloud/tcld/namespace/#accepted-client-ca), [delete](https://docs.temporal.io/cloud/tcld/namespace/#delete), [protección de borrado](https://docs.temporal.io/cloud/namespaces#namespace-deletion-protection) (`tcld namespace lifecycle set --enable-delete-protection`).  
- Pipelines: [Terraform Provider](https://docs.temporal.io/cloud/terraform-provider), [Cloud Ops API](https://docs.temporal.io/ops); autenticación con API keys: [Using API keys](https://docs.temporal.io/cloud/api-keys#using-apikeys).

**Tras el aprovisionamiento**

- **Edit:** Search Attributes, CA / [filtros de certificado](https://docs.temporal.io/cloud/certificates#manage-certificate-filters-using-temporal-cloud-ui), Codec, permisos, usuarios ([gestión en UI](https://docs.temporal.io/cloud/namespaces#manage-namespaces-in-temporal-cloud-using-temporal-cloud-ui)).  
- Activar **deletion protection** en Namespaces productivos.  
- Hasta **10** [tags](https://docs.temporal.io/cloud/namespaces#how-to-tag-a-namespace-in-temporal-cloud) por Namespace para inventario.

**Criterios del proveedor:** [Namespace best practices](https://docs.temporal.io/cloud/namespaces#what-are-some-namespace-best-practices), [limits](https://docs.temporal.io/cloud/limits), [managing namespace](https://docs.temporal.io/best-practices/managing-namespace).

**BCP:** nomenclatura alineada a estándares PEVE/Cloud; registrar en inventario región, retención, modo de auth, owner y enlace al procedimiento interno.

#### Pasos de primera implantación (cuenta nueva / primera vez)

1. **Contratación y alta de cuenta Temporal Cloud**  
   - Registro en [temporal.io/get-cloud](https://temporal.io/get-cloud) o suscripción vía [AWS Marketplace (Pay-As-You-Go)](https://aws.amazon.com/marketplace/pp/prodview-xx2x66m6fp2lo) (facturación por cuenta AWS).  
   - Para Google Cloud Marketplace, el proveedor indica contactar a [sales@temporal.io](mailto:sales@temporal.io).  
   - **BCP:** alinear compra, facturación y datos de contacto con **Compras / Finanzas / Cloud** y dejar registrado el **Account Owner** corporativo (no cuentas personales sin respaldo de gobierno).  
   - Revisar [pricing](https://docs.temporal.io/cloud/pricing) y límites por plan.

2. **Primer acceso y gobierno de la cuenta**  
   - Quien firma el alta queda como primer [**Account Owner**](https://docs.temporal.io/cloud/manage-access/roles-and-permissions#account-level-roles) en Temporal.  
   - **BCP:** planificar desde el inicio la **matriz de roles** (owners, admins de Namespace, desarrolladores, solo lectura), uso de cuentas **BCPDOM**/`alias@bcp.com.pe` donde aplique, y evitar dependencia de una sola persona (ver [Managing users](https://docs.temporal.io/cloud/users)).

3. **Aprovisionar Namespaces (primer y siguientes entornos)**  
   - Seguir la subsección **«Aprovisionamiento de Namespaces»** más arriba (datos previos, UI / `tcld` / Terraform, endpoints, retención, API key vs mTLS).  
   - **BCP:** un Namespace por línea base de entorno cuando aplique (p. ej. Dev / Cert / Prod) y nombres según estándares internos.

4. **Conectividad y política de red (antes de exponer Workers)**  
   - Valorar acceso por Internet vs [**PrivateLink (AWS)** o **Private Service Connect (GCP)**](https://docs.temporal.io/cloud/connectivity) y [**connectivity rules**](https://docs.temporal.io/cloud/connectivity#connectivity-rules) por Namespace.  
   - Tener presente el comportamiento de la [**Web UI**](https://docs.temporal.io/cloud/connectivity#web-ui-connectivity) respecto a las reglas del Namespace.  
   - **BCP:** aprobaciones de red, firewalls y salidas según **Seguridad perimetral** (ver §2.2).

5. **Credenciales de aplicación (Client / Worker)**  
   - Obtener o generar **API key** o cargar **certificados mTLS** según lo elegido en el Namespace; almacenar en **baúl corporativo** (p. ej. Vault), no en repositorios.  
   - Configurar **endpoints** del Namespace según documentación ([Namespaces](https://docs.temporal.io/cloud/namespaces)).

6. **Conectar Workers y clientes en el entorno del banco**  
   - Guías por SDK: [Connect to Temporal Cloud](https://docs.temporal.io/cloud/get-started#set-up-your-clients-and-workers) (Go, Java, Python, TypeScript, .NET, PHP, Ruby, etc.).  
   - Desplegar Workers en el clúster o plataforma aprobada (p. ej. AKS) con **variables de entorno** o secretos montados desde el baúl — sin hardcodear claves.

7. **Validación técnica (primera ejecución)**  
   - Ejecutar un **workflow de prueba** no sensible ([Start a workflow](https://docs.temporal.io/cloud/get-started#run-your-first-workflow) según SDK) y verificar en la **Web UI** (o vía CLI) que la cola, el historial y la observabilidad mínima responden.  
   - **BCP:** criterio de “listo para uso” según ambiente (Dev/Cert/Prod) y ticket/cab si aplica.

8. **Habilitar colaboración y cuentas de máquina**  
   - Invitar al equipo y asignar roles ([Managing users](https://docs.temporal.io/cloud/users)).  
   - Crear [**Service Accounts**](https://docs.temporal.io/cloud/service-accounts) para automatización (Terraform, CI/CD, `tcld`) separando identidades humanas y técnicas.

9. **Opcional según plan: SAML para la UI**  
   - Integrar IdP corporativo ([SAML authentication](https://docs.temporal.io/cloud/saml)) en planes que lo soporten (**Business**, **Enterprise**, **Mission Critical** según [pricing](https://docs.temporal.io/cloud/pricing#base_plans)).

10. **Continuidad del estándar**  
    - Dejar documentado el Namespace, dueño, región, modo de auth (API key vs mTLS), política de rotación y enlaces a procedimientos internos PEVE; repetir el esquema **por cada nuevo Namespace o entorno**.


| Concepto                               | Detalle                                                                                              |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Requerimiento de seguridad**         | La primera configuración debe cumplir políticas del banco (identidad, red, secretos, nomenclatura) y límites del producto. |
| **Tipo de ejecución — Automatizada**   | Fases posteriores: Terraform / `tcld` / pipelines para Namespaces y reglas de conectividad (definir). |
| **Tipo de ejecución — Manual**         | Alta de cuenta comercial, primer Account Owner, primera decisión API key vs mTLS, aprobaciones de red y SAML suelen ser manuales o semiautomáticas. |
| **Responsable post aprovisionamiento** | PEVE / dueño de plataforma + SQUADS que despliegan Workers.                                           |
| **Descripción**                        | La **configuración inicial** incluye el **aprovisionamiento de cada Namespace** (nombre, región, retención, auth, Codec opcional, permisos) y dejar **cuenta + conectividad + secretos + Workers** alineados al entorno; sin Workers el servicio no ejecuta lógica de negocio. |


**Procedimiento:** [Completar — aprovisionamiento Temporal Cloud (cuenta, Namespaces, conectividad)](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

#### Procedimientos de ejecución (completar enlaces)


| Fase / recurso                         | Enlace                                                                 |
| -------------------------------------- | ---------------------------------------------------------------------- |
| Aprovisionamiento de Namespaces       | [Completar](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)             |
| Contratación / Account Owner          | [Completar](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)             |
| Nomenclatura y etiquetas (tags)        | [Completar](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)             |
| Conectividad / PrivateLink / reglas    | [Completar](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)             |
| API keys / mTLS / Vault                | [Completar](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)             |
| Despliegue Workers (AKS / compute)     | [Completar](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)             |
| Automatización (Terraform / `tcld`)    | [Completar](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)             |


### 1.3 Autenticación y autorización (rol responsable)


| Concepto                               | Detalle                                                                                                                                                                                                 |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Requerimiento de seguridad**         | Autenticación y autorización sobre Temporal Cloud (gRPC al Namespace, usuarios UI).                                                                                                                     |
| **Automatizada**                       | PEVE / pipelines de despliegue de credenciales (definir).                                                                                                                                               |
| **Manual**                             | Configuración SAML con IdP, alta de certificados mTLS o políticas de Namespace según procedimiento.                                                                                                      |
| **Responsable post aprovisionamiento** | SQUADS / dueños de aplicación + Seguridad TI según matriz de accesos.                                                                                                                                   |
| **Descripción**                        | **gRPC:** [API keys](https://docs.temporal.io/cloud/api-keys) o [mTLS](https://docs.temporal.io/cloud/certificates). **UI:** [SAML](https://docs.temporal.io/cloud/saml). **RBAC:** [Roles and permissions](https://docs.temporal.io/cloud/manage-access/roles-and-permissions). |


**Procedimiento:** [Completar — modelo de accesos Temporal Cloud / SAML / API keys](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

### 1.4 Auditorías nativas, logs y trazabilidad (rol responsable)


| Concepto                               | Detalle                                                                                                                                 |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Requerimiento de seguridad**         | Disponer de logs de auditoría y trazabilidad de uso de la API y del entorno según documentación Cloud.                                  |
| **Automatizada**                       | Integración a SIEM / observabilidad corporativa (definir).                                                                              |
| **Manual**                             | Solicitud de logs a proveedor o configuración de destinos según contrato (definir).                                                      |
| **Responsable post aprovisionamiento** | Observability / SecOps / SQUADS (definir).                                                                                              |
| **Descripción**                        | Temporal Cloud monitorea logs del entorno **AWS** y **llamadas gRPC** (SDKs, CLI, Web UI); pueden ponerse a disposición del cliente ([Monitoring](https://docs.temporal.io/cloud/security)). |


**Procedimiento:** [Completar — ingesta auditoría Temporal a SIEM](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

**Consideraciones:**

- Coordinar dashboards y alertas con equipos de **Observability** según estándar del banco.
- Conservar trazabilidad de cambios en roles, API keys y certificados acorde a **Seguridad TI**.

### 1.5 Gestión de roles y matriz de roles / perfiles / permisos (rol responsable)


| Concepto                               | Detalle                                                                                                                                    |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **Requerimiento de seguridad**         | Configurar usuarios, Service Accounts y permisos acorde al principio de mínimo privilegio.                                                 |
| **Automatizada**                       | Repositorio o jobs de perfilamiento (si aplica).                                                                                            |
| **Manual**                             | Altas/bajas y revisiones periódicas de acceso.                                                                                              |
| **Responsable post aprovisionamiento** | SQUADS + Seguridad TI                                                                                                                       |
| **Descripción**                        | RBAC a nivel cuenta y Namespace: administradores, desarrolladores, solo lectura, etc. ([Roles and permissions](https://docs.temporal.io/cloud/manage-access/roles-and-permissions)). |


**Procedimiento:** [Completar — matriz RBAC Temporal Cloud](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

### 1.6 Reportes para gestión de usuarios (rol responsable)


| Concepto                               | Detalle                                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Requerimiento de seguridad**         | Capacidad de sustentar auditorías de identidad y acceso.                                         |
| **Automatizada**                       | No aplica como reporte nativo dedicado en producto.                                              |
| **Manual**                             | Seguridad TI / herramientas internas de gobierno de identidades.                                |
| **Responsable post aprovisionamiento** | Seguridad TI                                                                                     |
| **Descripción**                        | La plataforma gestiona usuarios vía UI y cuenta; no sustituye SIEM de RRHH — complementar con procesos internos. |


**Procedimiento:** [Completar — reportes y revisiones de acceso](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

### 1.7 Custodia / deshabilitación de usuarios por defecto o super-admin (rol responsable)


| Concepto                               | Detalle                                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Requerimiento de seguridad**         | Control de privilegios, rotación y baja de credenciales; sin cuentas genéricas inseguras.         |
| **Automatizada**                       | Donde exista integración con IdP / vault de secretos.                                            |
| **Manual**                             | Gestión de break-glass y cuentas de servicio — **Seguridad TI / SecOps**.                        |
| **Responsable post aprovisionamiento** | Seguridad TI                                                                                     |
| **Descripción**                        | [Service Accounts](https://docs.temporal.io/cloud/service-accounts), [API keys](https://docs.temporal.io/cloud/api-keys); según documentación del proveedor. **Contraseñas por defecto de tipo producto COTS:** **no aplica** (IdP / API keys / certificados). |


**Procedimiento:** [Completar — custodia cuentas privilegiadas y rotación](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

### 1.8 Identificación y aseguramiento de archivos y rutas de configuración

**No aplica** al plano de control Temporal Cloud (configuración no expuesta como archivos del tenant en SaaS).

**Sí aplica** a **Workers, clientes y pipelines** bajo control del banco: variables de entorno, certificados mTLS, manifests — seguir estándares de secretos y despliegue ([Completar procedimiento](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)).

### 1.9 Encriptación de password por defecto, reseteo o delegación al equipo COS

**No aplica** en el sentido de “password por defecto del servidor”; credenciales operativas: API keys, certificados, integración con **baúl corporativo** — ver [Key management](https://docs.temporal.io/key-management) y procedimiento interno de secretos.

### 1.10 Validación de vulnerabilidades y controles (rol responsable)


| Concepto                               | Detalle                                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Requerimiento de seguridad**         | Conocer postura de seguridad del servicio gestionado y cadena de dependencias del cliente.       |
| **Automatizada / Manual**              | Parcheo del **servicio Cloud**: operador **Temporal**; Workers e imágenes: **equipo aplicativo**. |
| **Responsable post aprovisionamiento** | PEVE / plataforma + SQUADS (Workers)                                                             |
| **Descripción**                        | Cifrado TLS **1.3**, reposo **AES-256-GCM** ([Encryption](https://docs.temporal.io/cloud/security)); pentest periódico declarado por el proveedor ([Testing](https://docs.temporal.io/cloud/security)); cumplimiento [Compliance](https://docs.temporal.io/cloud/security). |


**Criterios:**

- Seguimiento de **security advisories** de Temporal y actualización de SDKs/Workers en el banco.
- Separación clara de responsabilidad: plano de datos/servicio Cloud vs. código y runtime de Workers.

---

## 2. Seguridad por capas

### 2.1 Diagrama de arquitectura de red

El detalle de **conectividad** (Internet, **PrivateLink** / **GCP Private Service Connect**, reglas por Namespace) está en [Private network connectivity](https://docs.temporal.io/cloud/connectivity) y [Connectivity rules](https://docs.temporal.io/cloud/connectivity#connectivity-rules). Hostnames del plano de control y PrivateLink: [Control plane connectivity](https://docs.temporal.io/cloud/connectivity#control-plane-connectivity).

**Referencia interna BCP:** [Completar — arquitectura de red Temporal Cloud](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

### 2.2 Seguridad perimetral (Seguridad TI)


| Concepto                               | Detalle                                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Requerimiento de seguridad**         | Limitar exposición; autenticación obligatoria; segmentación acorde a política del banco.         |
| **Automatizada**                       | Reglas de conectividad en Temporal Cloud donde aplique.                                          |
| **Manual**                             | Diseño de firewall, rutas y opcionalmente PrivateLink/PSC — PEVE / Seguridad Perimetral.           |
| **Responsable post aprovisionamiento** | PEVE / SECOPS                                                                                    |
| **Descripción**                        | [Connectivity rules](https://docs.temporal.io/cloud/connectivity); API keys o mTLS. **Nota:** la **Web UI** puede seguir accesible por Internet aunque el Namespace tenga reglas restrictivas ([Web UI Connectivity](https://docs.temporal.io/cloud/connectivity#web-ui-connectivity)). |


**Procedimiento:** [Completar — perímetro y conectividad Temporal](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

**Nota:** Exigir **WAF estándar del banco** frente al **SaaS Temporal** **no aplica** como requisito del proveedor; valorar según política interna.

### 2.3 Configuración de aislamiento

**Aplica:** aislamiento lógico por **Namespace**; sin compartir datos entre Namespaces salvo **Temporal Nexus** u otros mecanismos explícitos ([Namespace isolation](https://docs.temporal.io/cloud/security), [Logical segregation](https://docs.temporal.io/cloud/security)).

### 2.4 Protocolos, formatos de archivo y servicios (SQUADS)


| Concepto                               | Detalle                                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Requerimiento de seguridad**         | Minimizar superficie: solo protocolos y prácticas necesarias y alineadas a estándar del banco.   |
| **Automatizada**                       | Gobierno de APIs / estándares de serialización (definir).                                        |
| **Manual**                             | Revisión de integraciones y tamaños de payload.                                                  |
| **Responsable post aprovisionamiento** | PEVE / SQUADS                                                                                    |


**Descripción:** **TLS 1.3**; **mTLS** como autenticación, no sustituto del cifrado ([TLS vs mTLS](https://docs.temporal.io/cloud/security)). **Payloads:** [Data conversion](https://docs.temporal.io/dataconversion); cifrado opcional [Data encryption](https://docs.temporal.io/production-deployment/data-encryption).

**Lineamientos:**

- Tratar payloads con datos personales o sensibles según **clasificación de datos** del banco; valorar **Payload Codec** y **Codec Server**.

### 2.5 Aseguramiento de canal (rol responsable)


| Concepto                               | Detalle                                                                 |
| -------------------------------------- | ----------------------------------------------------------------------- |
| **Requerimiento de seguridad**         | Confidencialidad e integridad en tránsito.                              |
| **Automatizada**                       | Por defecto en Temporal Cloud (TLS 1.3).                              |
| **Manual**                             | Validación de pin/hostnames en clientes corporativos si aplica.        |
| **Responsable post aprovisionamiento** | Seguridad TI / SQUADS                                                   |
| **Descripción**                        | [Encryption](https://docs.temporal.io/cloud/security) — TLS **1.3** en todas las conexiones. |


**Procedimiento:** Documentación oficial: [Encryption](https://docs.temporal.io/cloud/security).

### 2.6 Custodia de certificados digitales (rol responsable)


| Concepto                               | Detalle                                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Requerimiento de seguridad**         | Custodia de **certificados de cliente (mTLS)** y **API keys** conforme a política del banco.   |
| **Automatizada**                       | Integración con baúl (p. ej. Vault) — definir.                                                    |
| **Manual**                             | Renovación y revocación según CA del Namespace.                                                   |
| **Responsable post aprovisionamiento** | Seguridad TI / PEVE                                                                               |
| **Descripción**                        | [Certificates](https://docs.temporal.io/cloud/certificates); límites [Certificates limits](https://docs.temporal.io/cloud/limits#certificates). [API keys](https://docs.temporal.io/cloud/api-keys). |


**Procedimiento:** [Completar — custodia mTLS y API keys](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

### 2.7 Registro en el WAF estándar del banco

**No aplica** como requisito específico de la plataforma en documentación Temporal. Si política perimetral del banco lo exige, documentar excepción o enfoque en procedimiento interno.

### 2.8 Registro de dominios, subdominios o hostname en DNS

**Aplica** para **Codec Server**, callbacks **SAML** u otros endpoints bajo dominio del banco. Endpoints del servicio Cloud: `*.tmprl.cloud`, `*.api.temporal.io` según [Namespaces](https://docs.temporal.io/cloud/namespaces) y [Connectivity](https://docs.temporal.io/cloud/connectivity).

**Procedimiento:** [Completar — DNS y certificados dominio propio](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

---

## 3. Seguridad por diseño

### 3.1 Diagrama de componentes e integración con controles de seguridad

**Controles aplicados** (resumen [Security model — Temporal Cloud](https://docs.temporal.io/cloud/security)):

- **Autenticación y autorización:** API keys, mTLS, SAML (UI), RBAC.
- **Cifrado:** TLS 1.3 en tránsito; AES-256-GCM en reposo en componentes indicados por el proveedor.
- **Aislamiento:** Namespaces; límites APS, OPS, RPS.
- **Datos de aplicación:** cifrado opcional con Data Converter / Codec Server para que el servicio no lea contenido sensible.

### 3.2 Integración con herramientas o aplicaciones del banco (rol responsable)

**Integración con el entorno del banco**

- **Workers y clientes** en compute controlado por el banco ([Code execution boundaries](https://docs.temporal.io/cloud/security)).
- **APIs internas, colas y bases** mediante Activities, Child Workflows, Signals, Queries, etc.
- **Observabilidad** acoplada a stacks corporativos donde aplique.

### 3.3 Aseguramiento de integraciones y conectores

**Temporal Nexus:** comunicación entre Namespaces con allowlists y autenticación de Workers ([Nexus Security](https://docs.temporal.io/nexus/security)). **Payloads** en Nexus: mismo modelo de Data Converter ([Payload encryption](https://docs.temporal.io/nexus/security#payload-encryption-and-data-converter)).

### 3.4 Controles adicionales sobre componentes estándar

**Parcialmente aplica:** extensión mediante **Data Converter**, **Payload Codec** y **Codec Server**; no hay catálogo “cerrado” adicional en producto más allá de configuración de cuenta/Namespace y estas extensiones.

### 3.5 Intercambio de secretos y baúl estándar (rol responsable)


| Concepto                               | Detalle                                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Requerimiento de seguridad**         | Proteger API keys, certis y claves de cifrado de payload; uso del baúl corporativo.              |
| **Automatizada**                       | PEVE / pipelines (definir).                                                                     |
| **Manual**                             | Altas de secretos y rotación.                                                                     |
| **Responsable post aprovisionamiento** | SQUADS                                                                                           |
| **Descripción**                        | Referencia proveedor: [Key management](https://docs.temporal.io/key-management) (incl. ejemplo Vault). |


**Procedimiento:** [Completar — secretos y Vault / baúl estándar](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

### 3.6 Disponibilidad y continuidad de la plataforma

**Aplica según producto:** [High Availability](https://docs.temporal.io/cloud/high-availability) para Namespaces elegibles. SLA y multi-región: revisar contrato y [docs.temporal.io/cloud](https://docs.temporal.io/cloud).

**Procedimiento interno:** [Completar — continuidad negocio Temporal](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

### 3.7 Backups y retención según políticas del banco (rol responsable)


| Concepto                               | Detalle                                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Requerimiento de seguridad**         | Retención de historial y continuidad acordes a negocio y cumplimiento.                           |
| **Automatizada**                       | Retención por Namespace en Cloud (configurable).                                               |
| **Manual**                             | Exportación/archivado de negocio fuera de Temporal — diseño de solución.                        |
| **Responsable post aprovisionamiento** | SQUADS / Arquitectura                                                                             |
| **Descripción**                        | No hay “backup descargable” clásico del historial como ficheros genéricos; retención por defecto **30 días**, rango **1–90 días** ([Default Retention Period](https://docs.temporal.io/cloud/limits#default-retention-period)). |


**Procedimiento:** [Completar — retención y exportación historiales](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

**Resumen:**

1. **Backups tradicionales tipo BD:** no documentados en los mismos términos que on-premise.
2. **Retención Event History:** configurable por Namespace en Cloud.
3. **Exportación / archivo** para negocio: responsabilidad de la aplicación y políticas internas.
4. **Incidentes y soporte:** definir escalamiento con proveedor y mesa interna.

### 3.8 Gobierno y ciclo de vida de la plataforma (rol responsable)

**Ciclo de vida y actualizaciones**

Temporal Cloud es **SaaS** gestionado por **Temporal**:

- Actualizaciones del servicio en la nube las opera el proveedor.
- El banco gestiona Namespaces, conectividad, identidades, límites y el ciclo de vida de **Workers** y **SDKs**.

---

## 4. Seguridad del dato y en el desarrollo

### 4.1 Diagrama de flujo de información y clasificación de datos

**No aplica** diagrama en documentación del producto. **Cliente:** clasificación de datos y qué puede transitar en **Payloads** — gobierno interno de datos; referencia técnica [Data encryption](https://docs.temporal.io/production-deployment/data-encryption).

### 4.2 Gobierno y ciclo de vida del dato

**No aplica** marco único en documentación Temporal; **Cliente:** alinear a políticas de gobierno de datos del banco.

### 4.3 Normativas, cumplimientos y protección de datos

Referencia proveedor: [Compliance — Temporal Cloud](https://docs.temporal.io/cloud/security) (p. ej. SOC 2 Type 2, GDPR, HIPAA); detalle contractual y [Trust Center](https://trust.temporal.io/).

### 4.4 Aseguramiento del repositorio de datos o metadatos

Datos de historial y visibilidad bajo modelo **Temporal Cloud** con **cifrado en reposo** descrito en [Encryption](https://docs.temporal.io/cloud/security). Uso de un **data store interno del banco** como repositorio “oficial” de metadatos Temporal: **no aplica** salvo arquitectura híbrida explícita.

### 4.5 Encriptación en reposo y en tránsito (rol responsable)


| Concepto                               | Detalle                                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| **Requerimiento de seguridad**         | Cumplir requisitos de cifrado en tránsito y reposo según política y oferta Cloud.                |
| **Automatizada**                       | Cifrado gestionado por Temporal Cloud en capas indicadas en documentación.                       |
| **Manual**                             | Cifrado de payload en cliente; operación de **Codec Server**.                                    |
| **Responsable post aprovisionamiento** | SQUADS                                                                                           |
| **Descripción**                        | Tránsito TLS **1.3**; reposo **AES-256-GCM** en componentes indicados ([Encryption](https://docs.temporal.io/cloud/security)). Payload: [Data Converter](https://docs.temporal.io/dataconversion); UI: [Codec Server](https://docs.temporal.io/codec-server). |


**Cifrado en tránsito**

- TLS **1.3** entre clientes, Workers y servicio Cloud.

**Cifrado en reposo**

- Según documentación del proveedor para almacenamiento de historial y visibilidad ([Encryption](https://docs.temporal.io/cloud/security)).

**Codec Server y UI Cloud**

- Política de HTTPS, CORS y validación de tokens conforme a [Codec Server setup](https://docs.temporal.io/production-deployment/data-encryption#codec-server-setup).

**Procedimiento:** [Completar — Codec Server y política de descifrado en UI](https://bcp-ti.atlassian.net/wiki/spaces/PEVE)

### 4.6 Buenas prácticas de desarrollo seguro

- Límites de tamaño de payload e historial ([Workflow limits](https://docs.temporal.io/workflow-execution/limits), [BlobSizeLimitError](https://docs.temporal.io/troubleshooting/blob-size-limit-error)).
- **Throttling:** [Throttling behavior](https://docs.temporal.io/cloud/limits#throttling-behavior) y manejo de `ResourceExhausted`.
- Patrones en [Develop](https://docs.temporal.io/develop).

### 4.7 Integración al modelo de desarrollo (Waterfall o Agile)

**No aplica** como requisito en documentación Temporal. **Cliente:** SDLC, pipelines y gates internos — [Completar estándar PEVE / Agile](https://bcp-ti.atlassian.net/wiki/spaces/PEVE).

---

## 5. Referencias


| Título                              | URL                                                                                                                                 | Descripción breve                                          |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Seguridad Temporal Cloud            | [https://docs.temporal.io/cloud/security](https://docs.temporal.io/cloud/security)                                                 | Modelo de seguridad, cifrado, cumplimiento, monitoreo.      |
| Conectividad (PrivateLink, PSC)     | [https://docs.temporal.io/cloud/connectivity](https://docs.temporal.io/cloud/connectivity)                                         | Reglas, UI, conectividad privada.                          |
| API keys                            | [https://docs.temporal.io/cloud/api-keys](https://docs.temporal.io/cloud/api-keys)                                                 | Autenticación de aplicaciones y rotación.                  |
| Certificados mTLS                   | [https://docs.temporal.io/cloud/certificates](https://docs.temporal.io/cloud/certificates)                                           | mTLS en Cloud.                                             |
| SAML                                | [https://docs.temporal.io/cloud/saml](https://docs.temporal.io/cloud/saml)                                                         | SSO para usuarios de la UI.                                |
| Límites del sistema                 | [https://docs.temporal.io/cloud/limits](https://docs.temporal.io/cloud/limits)                                                     | APS, OPS, RPS, retención, certificados.                    |
| Cifrado de datos (Payload, Codec)   | [https://docs.temporal.io/production-deployment/data-encryption](https://docs.temporal.io/production-deployment/data-encryption) | Payload Codec y Codec Server.                              |
| Conversión de datos                 | [https://docs.temporal.io/dataconversion](https://docs.temporal.io/dataconversion)                                                 | Data Converter.                                            |
| Gestión de claves                   | [https://docs.temporal.io/key-management](https://docs.temporal.io/key-management)                                                 | Buenas prácticas y KMS.                                    |
| Nexus Security                      | [https://docs.temporal.io/nexus/security](https://docs.temporal.io/nexus/security)                                                 | Seguridad en integraciones Nexus.                          |
| Roles y permisos                    | [https://docs.temporal.io/cloud/manage-access/roles-and-permissions](https://docs.temporal.io/cloud/manage-access/roles-and-permissions) | RBAC en Cloud.                                      |
| Portal seguridad plataforma         | [https://docs.temporal.io/security](https://docs.temporal.io/security)                                                             | Visión general Temporal Platform.                          |
| Trust Center                        | [https://trust.temporal.io/](https://trust.temporal.io/)                                                                           | Certificaciones y confianza.                               |
| Whitepaper seguridad en la nube     | [https://temporal.io/pages/cloud-security-white-paper](https://temporal.io/pages/cloud-security-white-paper)                         | Documento comercial referenciado por el proveedor.         |


---

## 6. Glosario


| Término                       | Definición                                                                                                       |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **Temporal Platform**         | Plataforma de orquestación de workflows durable ([Temporal](https://docs.temporal.io/temporal)).               |
| **Temporal Cloud**            | Oferta SaaS de Temporal ([Temporal Cloud](https://docs.temporal.io/cloud)).                                    |
| **Namespace**                 | Unidad de aislamiento lógico ([Namespaces](https://docs.temporal.io/namespaces)).                                |
| **Workflow**                  | Ejecución durable de orquestación ([Workflows](https://docs.temporal.io/workflows)).                             |
| **Worker**                    | Proceso que ejecuta workflows y activities ([Workers](https://docs.temporal.io/workers)).                       |
| **Task Queue**                | Cola de tareas para Workers ([Task Queues](https://docs.temporal.io/task-queue)).                              |
| **Data Converter / Payload Codec** | Serialización y cifrado opcional de payloads ([Data conversion](https://docs.temporal.io/dataconversion)). |
| **Codec Server**              | HTTP para decodificar payloads en UI/CLI ([Codec Server](https://docs.temporal.io/codec-server)).              |
| **mTLS**                      | Autenticación mutua con certificados X.509 ([Certificates](https://docs.temporal.io/cloud/certificates)).     |
| **API key**                   | Token para autenticación en Cloud ([API keys](https://docs.temporal.io/cloud/api-keys)).                       |
| **Temporal Nexus**            | Comunicación controlada entre Namespaces ([Nexus](https://docs.temporal.io/nexus)).                            |
| **APS / OPS / RPS**           | Límites de acciones, operaciones y solicitudes/s ([Limits](https://docs.temporal.io/cloud/limits)).              |


---

*Documento en formato LBS alineado a `temporal-hardening/temporal-hardening.md` (Confluent Cloud); sustituir enlaces “Completar” en Confluence por páginas aprobadas.*
