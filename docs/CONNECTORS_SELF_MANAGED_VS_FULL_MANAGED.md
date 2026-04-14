# Presentación: conectores Kafka self-managed y full-managed

Documento para **comunicar valor** (negocio y TI) y **fundamento técnico** del modelo **full-managed** en Confluent Cloud frente al **self-managed** que el banco ya utiliza, y de cómo el **pipeline Git (GitHub Actions + Terraform + Vault)** materializa esa capacidad en la práctica.

---

## Mensaje en una frase

**Self-managed**: el banco opera el motor de integración (Kafka Connect) de punta a punta. **Full-managed**: se opera el **contrato** de la integración (configuración, identidades, topics, esquemas) sobre un **servicio de conectores** que Confluent mantiene; el despliegue queda **industrializado** en Git, con trazabilidad y secretos desde Vault.

---

## Por qué importa (valor)

- **Velocidad**: menos fricción para publicar o ajustar integraciones cuando el trabajo repetitivo de plataforma lo absorbe el servicio administrado.
- **Enfoque del equipo**: las horas dejan de ir a parches, capacidad y “mantener Connect arriba” y pasan a **calidad de datos, contratos y SLAs** con negocio.
- **Gobernanza en un banco**: cambios **revisables en pull request**, historial en Git, separación de secretos (Vault) y menos configuraciones únicas difíciles de auditar.
- **Coherencia con Confluent Cloud**: Kafka, Schema Registry y conectores en el **mismo ecosistema** reducen divergencia operativa y simplifican soporte y documentación.
- **Escala organizacional**: un **estándar por aplicación (CODAPP)** permite que más equipos integren; conviene contrastar con el patrón **un AKS por conector**, que **multiplica** silos operativos y coste fijo por clúster.

---

## Qué es cada modelo (técnico)

### Self-managed

**Kafka Connect** corre en **infraestructura del banco** (VMs, Kubernetes, etc.). En el modelo actual que se usa como referencia, **cada conector vive en un clúster AKS distinto** (aislamiento por integración). El equipo:

- Despliega y actualiza el **runtime** de Connect y los **plugins** (connectors) **en cada AKS** (plantillas, versiones y ventanas de cambio **multiplicadas**).
- Define **alta disponibilidad** (varios workers), reparto de tareas y recuperación ante fallas.
- Gestiona **almacenamiento interno** de Connect (offsets, configuración, estado según el modo del conector).
- Alinea **red** (firewalls, DNS, TLS), **observabilidad** (métricas, logs, alertas) y **seguridad** (credenciales, rotación) con políticas internas.

En resumen: **quien opera asume el rol de SRE del conector y del cluster Connect**.

### Full-managed (Confluent Cloud)

Confluent expone **conectores administrados** como parte del servicio en la nube: el **plano de control** y la **operación base** del servicio de Connect corren **bajo responsabilidad del proveedor**. El equipo:

- **Define** el **conector** (clase, topics, formato, opciones de errores/DLQ, etc.).
- **Asigna** **identidades** (por ejemplo, Service Accounts) y **permisos** alineados con Kafka y Schema Registry.
- **Versiona** y aplica la configuración mediante **API / Terraform**, no mediante SSH a un cluster propio.

En resumen: **el banco es dueño del contrato de integración y de la gobernanza**; el motor como servicio es **operado por Confluent** en esa capa.

---

## Comparativa técnica directa

| Aspecto | Self-managed | Full-managed (Confluent Cloud) |
|--------|--------------|--------------------------------|
| **Runtime Connect** | Propio (instalación, versión, parches) | Servicio administrado |
| **Alta disponibilidad / workers** | Diseño y operación internos | Cubierto en el modelo de servicio |
| **Actualización de plataforma** | Ventanas de cambio internas | Evolución del servicio en la nube |
| **Definición del conector** | APIs REST Connect / archivos / CI propia | API Confluent + **IaC** (por ejemplo, Terraform) |
| **Secretos** | Patrón interno (vault, otro vault, etc.) | Encaje con **Vault + pipeline** (sin credenciales en el repo) |
| **Observabilidad** | Stack interno obligatorio | Nube + prácticas del proveedor + integraciones propias |
| **Red** | Peering/VPN/firewall hacia orígenes y Kafka | Integración con **red privada / endpoints** según diseño Confluent |
| **Topología / tenancy** | **Un AKS por conector** (varios clústeres que operar) | Sin **N** clústeres AKS en el banco para esos conectores; capacidad de Connect en el **servicio** |

---

## Comparación de costos (marco para el banco)

Escenario con **supuestos fijos** (adecuado para **PPT**): **un** sink **Azure Data Lake Storage Gen2 (ADLS)**; **`tasks.max` = 3**; **2 workers** de Kafka Connect en **1 AKS** (self-managed); **15 TB/mes** (**15 000 GB/mes**) hacia ADLS, criterio Confluent **pre-compresión** para `$/GB`. **USD/mes**. **No** incluye cluster Kafka ni Schema Registry en Confluent.

**Full-managed (cálculo fijo):** [precios públicos Connect](https://www.confluent.io/confluent-cloud/connect-pricing/); conector [ADLS Gen2 Sink](https://docs.confluent.io/cloud/current/connectors/cc-azure-datalakeGen2-storage-sink.html) a **0,026 $/tarea·h** y **730 h/mes** → **3 × 0,026 × 730 = 56,94** (en la tabla **57 $/mes**); tráfico **15 000 GB × 0,025 $/GB = 375 $/mes** → **432 $/mes** en total conector.

**Self-managed (imputación fija de ejemplo):** **400** (AKS + nodos, 2 workers) + **90** (observabilidad / logs) + **55** (red / egress) + **175** (licencia y soporte del stack Connect) = **720 $/mes**. La fila opcional de **FTE** usa **750 $/mes** (ejemplo **0,0625 FTE** a **12 000 $/mes**); sustituir por el coste hora interno del banco.

**Lectura de la columna «Diferencia»:** **self-managed − full-managed** (positivo = más caro en self en esa partida). El **ahorro %** es **(total self − total full) / total self**.

### Cuadro para presentación *(USD/mes)*

| Partida | Self-managed | Full-managed | Diferencia *(self − full)* |
|---------|-------------:|-------------:|-----------------------------:|
| AKS y cómputo (1 clúster, 2 workers) | 400 | 0 | 400 |
| Observabilidad y logs | 90 | 0 | 90 |
| Red / egress | 55 | 0 | 55 |
| Licencia y soporte (stack Connect) | 175 | 0 | 175 |
| Confluent — tareas del conector (3) | 0 | 57 | −57 |
| Confluent — tráfico de datos (15 TB) | 0 | 375 | −375 |
| **Total (sin FTE)** | **720** | **432** | **288** |
| Tiempo imputado (FTE) | 750 | 0 | 750 |
| **Total (con FTE)** | **1 470** | **432** | **1 038** |

**Nota (FTE):** fila opcional en la lámina si se quiere mostrar carga de equipo; el coste **432** del modelo full-managed **no** incluye el mismo concepto de FTE.

**Resumen:** sin FTE, **ahorro 288 $/mes** (**40 %** sobre 720). Con FTE de ejemplo, **ahorro 1 038 $/mes** (**71 %** sobre 1 470).

### Inventario del escenario modelado

| Concepto | Valor |
|----------|--------|
| Conector | **Azure Data Lake Storage Gen2** sink |
| `tasks.max` | **3** |
| Workers (self-managed) | **2** en **1 AKS** |
| Volumen | **15 TB/mes** |

Fórmulas de referencia: `coste_tareas = tareas × $/tarea/h × 730`; `coste_datos = GB_mes × $/GB`.

### Self-managed: de qué está hecho el coste (TCO)

Aquí el gasto **no** suele aparecer como “línea de conector” en una factura, sino como **capacidad y tiempo de personas**:

- **Infraestructura**: la simulación de costes de arriba usa **un AKS con 2 workers** para **un** sink ADLS; en otras topologías del banco (p. ej. **un AKS por conector**) el **coste fijo por clúster** se **multiplica** con el número de integraciones.
- **Licencias y soporte**: uso de **Confluent Platform** (u otra distribución comercial), **suscripción de soporte** o **acuerdos por núcleo/nodo**; en modelos solo **Apache Kafka/Connect OSS** el coste de licencia es **cero**, pero suele compensarse con **contrato de soporte** o asumir el riesgo operativo.
- **Operación**: parches del runtime, actualización de **plugins**, alta disponibilidad, recuperación ante fallos, ajuste de recursos.
- **Observabilidad y seguridad**: métricas, logs, alertas, hardening, gestión de credenciales y cumplimiento (encaje con políticas del banco).
- **Coste de oportunidad**: horas de equipos de plataforma que dejan de dedicarse a otros riesgos o productos.

Para comparar en serio hace falta un **modelo interno** (coste hora de plataforma, número de FTE imputados, amortización de HW/cloud interno, etc.).

### Full-managed (Confluent Cloud): dimensiones típicas de facturación

En el modelo público de **conectores administrados** en Confluent Cloud, los importes dependen sobre todo de:

- **Uso por tarea y tiempo** (facturación por tarea y hora, según tipo de conector y condiciones del contrato).
- **Tráfico de datos** asociado al conector (p. ej. GB procesados según la definición de facturación del proveedor; suele referirse a datos **descomprimidos**).
- **Opciones añadidas** si aplican: por ejemplo cluster **dedicado** de Connect, **PrivateLink** u otros suplementos descritos en la documentación y la lista de precios.

Los precios **cambian por región, moneda, acuerdo empresarial y promociones**; no sustituyen a una cotización. Referencia oficial: [Managed Kafka Connector Pricing (Confluent)](https://www.confluent.io/confluent-cloud/connect-pricing/) y [Billing overview (Confluent Cloud)](https://docs.confluent.io/cloud/current/billing/overview.html).

### Tabla comparativa (enfoque TCO, no solo “ticket”)

| Dimensión | Self-managed | Full-managed (Confluent Cloud) |
|-----------|--------------|--------------------------------|
| **Visibilidad en factura** | Repartido en cómputo, red, licencias, herramientas y personal | Líneas de uso Confluent (tareas, datos, opciones de red/cluster) **más** el Kafka/entorno ya contratado |
| **Coste marginal de un conector nuevo** | Nuevo consumo de capacidad + posible ampliación de soporte/operación | Sobre todo **tareas activas** y **volumen**; conviene dimensionar `tasks.max` con criterio |
| **Conectores pausados** | Sigue habiendo coste de plataforma subyacente | Sigue habiendo coste de **tareas asignadas** según política de facturación; para dejar de facturar por ese conector suele requerirse **eliminarlo** (confirmar en la guía vigente de billing) |
| **FTE / operación** | Mayor carga en el banco en runtime Connect y plugins | Menor carga en “mantener el motor”; sigue haciendo falta operar **integración, red hacia sistemas destino y gobierno** |

### Cómo usar este apartado con FinOps (orden de trabajo sugerido)

1. **Inventario**: por conector crítico (aquí: **ADLS Gen2 sink**), `tasks.max` efectivo y GB/día (o MB/s); repetir el mismo patrón para otros destinos si hace falta un agregado.
2. **Lado self-managed**: coste imputado del **AKS** que aloja ese Connect (o suma de clústeres si hay **un AKS por conector**), **licencia**, red, observabilidad y **%FTE** anualizado.
3. **Lado full-managed**: estimación con la **calculadora / pricing** de Confluent y el contrato vigente (no con números genéricos de un documento interno).
4. **Revisión**: si cambian **volumen** o **`tasks.max`**, repetir el cuadro con los mismos importes fijos por línea (self) y recalcular tareas + GB en Confluent; el coste administrado suele **escalar con el dato** y con las tareas, no solo con el número de conectores.

Con el ejemplo del cuadro (**un sink ADLS**, `tasks.max` **3**, **15 TB/mes**), la pregunta útil no es solo “¿cuánto cuesta el clúster?”, sino “¿cuántas **tareas** corren y cuánto **volumen** mueven?”: ahí es donde convergen self-managed (capacidad a dimensionar) y full-managed (precio por uso declarado por el proveedor).

---

## Cómo se materializa el full-managed en este programa (stack)

Sin entrar en el detalle de cada archivo (eso está en el modelo operativo), la **cadena técnica** es:

1. **Git**: configuración declarativa por conector y entorno (JSON no sensible, YAML por entorno, referencias a secretos en Vault).
2. **GitHub Actions**: orquesta el flujo (checkout, credenciales de Terraform, obtención de secretos del conector, `terraform plan/apply`).
3. **Vault**: almacena credenciales; el pipeline las **lee** y las inyecta como variables sensibles a Terraform (no como texto en el repositorio).
4. **Terraform (provider Confluent)**: converge el estado deseado del recurso `confluent_connector` (config no sensible + sensible, estado del conector, cluster y entorno de Confluent Cloud).

Esto convierte cada cambio de integración en un **cambio de software**: revisable, repetible y auditable.

Referencia de convenciones y estructura: [CONNECTORS_OPERATIONAL_MODEL.md](./CONNECTORS_OPERATIONAL_MODEL.md).

---

## Diagrama mental (flujo de despliegue)

```mermaid
flowchart LR
  subgraph repo [Repositorio Git]
    JSON[JSON por entorno]
    YAML[YAML vars y rutas Vault]
  end
  subgraph cicd [GitHub Actions]
    VA[autenticación Vault]
    TF[Terraform]
  end
  subgraph cc [Confluent Cloud]
    KC[cluster Kafka]
    SR[Schema Registry]
    FMC[conectores full-managed]
  end
  JSON --> TF
  YAML --> VA
  VA --> TF
  TF --> FMC
  FMC --> KC
  FMC --> SR
```

---

## Cierre (pitch)

El banco ya sabe integrar con **Connect propio**. El salto a **full-managed** no es reemplazar el “qué” (se sigue moviendo datos entre sistemas y Kafka), sino **elevar el “cómo”**: menos operación de plataforma, más **estándar cloud**, más **trazabilidad** y un camino claro para que **más equipos** publiquen integraciones bajo el **mismo marco** de seguridad y automatización.

Para profundizar en carpetas, permisos, DLQ y variables por entorno: [CONNECTORS_OPERATIONAL_MODEL.md](./CONNECTORS_OPERATIONAL_MODEL.md).
