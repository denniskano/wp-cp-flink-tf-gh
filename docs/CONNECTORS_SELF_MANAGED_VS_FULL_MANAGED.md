# Conectores Kafka: self-managed y full-managed

## Propósito de este documento

En la organización hemos operado conectores **self-managed** (Kafka Connect desplegado y operado por equipos internos). Este repositorio y el flujo con **GitHub Actions** y **Terraform** para **Confluent Cloud Full-Managed Connectors** representan una **evolución deliberada** del modelo: más estándar, más auditable y con menos carga operativa sobre los equipos que antes mantenían clusters de Connect.

Este texto está pensado para **presentar** el cambio a equipos de negocio y tecnología: qué implica cada modelo, por qué tiene sentido avanzar hacia full-managed y qué beneficios concretos obtiene el banco.

---

## Dos formas de ejecutar Kafka Connect

### Self-managed (lo que ya conocemos)

**Self-managed** significa que **nosotros** somos responsables del ciclo de vida de Kafka Connect:

- Aprovisionamiento y parcheo de máquinas o contenedores donde corre Connect.
- Escalado (tasks, réplicas, recursos CPU/memoria, almacenamiento de offsets/configs).
- Alta disponibilidad, backups operativos, monitoreo y alertas propias.
- Coordinación con red, seguridad y cumplimiento para exponer conectores hacia sistemas externos.
- Actualización de versiones de Connect y de conectores; resolución de incompatibilidades.

En la práctica, el banco **posee el “motor”** y la **operación 24/7** asociada.

### Full-managed (Confluent Cloud)

**Full-managed** en Confluent Cloud significa que **Confluent opera** el servicio de conectores sobre la plataforma gestionada:

- El proveedor mantiene la infraestructura del servicio, actualizaciones de plataforma y buena parte de la operación repetitiva.
- Los equipos se centran en **qué** integrar (configuración, topics, esquemas, permisos) y en **gobernanza** (IaC, revisión de cambios, segregación por aplicación).
- La integración con Kafka, Schema Registry y políticas de la nube queda **alineada** con el ecosistema Confluent en lugar de divergencias por “Connect casero”.

En la práctica, el banco **posee el contrato de integración y la gobernanza**; el **motor** pasa a ser un servicio gestionado.

---

## Comparativa resumida

| Dimensión | Self-managed | Full-managed (Confluent Cloud) |
|-----------|--------------|--------------------------------|
| **Responsabilidad operativa** | Alta (equipo interno) | Menor en capa de plataforma; foco en configuración y gobierno |
| **Tiempo de equipo en “mantener el conector encendido”** | Sustancial | Redirigible a valor de negocio (nuevas integraciones, calidad de datos) |
| **Homogeneidad entre equipos** | Depende de cada despliegue | Facilitada por estándar único (modelo CODAPP, JSON/YAML, pipelines) |
| **Trazabilidad de cambios** | Variable (runbooks, tickets, scripts) | **Git + revisiones + despliegue automatizado** |
| **Seguridad y secretos** | Diseño propio por cluster | Integración con **Vault** y variables por entorno; menos credenciales en repos |
| **Escalado y parches de plataforma** | Planificación interna | Gestionado por el proveedor en la capa de servicio |
| **Coste** | CAPEX/OPEX de infra + personas | Modelo de servicio cloud; suele compensar al reducir esfuerzo operativo |

La tabla no pretende decir que self-managed sea “malo”: ha servido y puede seguir siendo válido en nichos. La tesis es que **full-managed + IaC** encaja mejor con una **estrategia de industrialización** del banco.

---

## Por qué esta evolución tiene sentido para el banco

### Menos fricción operativa, más foco en integraciones

Los equipos dejan de invertir ciclos en **parches, capacidad y incidentes de plataforma** de Connect y pueden orientarlos a **calidad de datos, contratos, SLAs con negocio** y nuevas fuentes o destinos.

### Industrialización con Git y automatización

Un conector deja de ser “un despliegue manual en un servidor” y pasa a ser **configuración versionada**, revisable y desplegable por **GitHub Actions**. Eso mejora:

- **Auditoría** (quién cambió qué y cuándo).
- **Reproducibilidad** entre DES, CER y PRO.
- **Recuperación** ante errores (rollback por revert).

### Alineación con Confluent Cloud

Si Kafka y Schema Registry ya viven en **Confluent Cloud**, los conectores full-managed **cierran el circuito** en el mismo ecosistema: menos saltos de red ad-hoc, menos piezas sueltas y un camino más claro para soporte y documentación oficial.

### Riesgo y cumplimiento

- Menos superficie **auto-gestionada** implica menos variabilidad entre entornos y menos “configuraciones únicas” difíciles de auditar.
- Los secretos pueden fluir desde **Vault** hacia el pipeline, en línea con prácticas ya deseables en un banco.

### Escalabilidad organizacional

El modelo por **CODAPP** (cada aplicación con su carpeta de conectores y convenciones compartidas) permite que **más equipos** desplieguen integraciones **sin** multiplicar silos operativos de Connect.

---

## Cómo encaja el nuevo proceso (visión de alto nivel)

El repositorio materializa la evolución así:

1. **Definición declarativa**: JSON por entorno para lo no sensible y YAML para variables y referencias a secretos.
2. **Automatización**: workflow que inicializa Terraform, resuelve identidades en Confluent y aplica cambios de forma controlada.
3. **Secretos**: integración con **Vault** para no persistir contraseñas en el código.
4. **Operación documentada**: el modelo operativo detalla estructura, convenciones y buenas prácticas.

Para el detalle técnico del modelo full-managed en este repo, ver [CONNECTORS_OPERATIONAL_MODEL.md](./CONNECTORS_OPERATIONAL_MODEL.md).

---

## Migración desde self-managed (mensaje para stakeholders)

No es un “big bang” obligatorio en todas las integraciones a la vez. Un enfoque sensato suele ser:

1. **Priorizar** conectores con alto coste operativo oriesgo de obsolescencia.
2. **Pilotar** en DES/CER con el pipeline Git + Terraform y validar con negocio.
3. **Estandarizar** plantillas y permisos (Service Accounts, topics, DLQ donde aplique).
4. **Planificar** el apagado gradual de capacidad self-managed conforme las cargas migran.

Cada caso puede tener matices (latencia, requisitos de red privada, conectores aún no disponibles como full-managed); eso se trata caso a caso, pero **la dirección** es clara: **más servicio gestionado, más automatización, menos operación artesanal**.

---

## Cierre

El paso de **conectores self-managed** a **full-managed con despliegue por GitHub Actions y Terraform** no es solo un cambio de herramienta: es **madurez operativa** (menos toil, más gobierno), **mejor trazabilidad** para un entorno regulado y **escalabilidad** para que más equipos integren datos con el mismo estándar.

Si tu área quiere profundizar en el modelo de carpetas, permisos o el flujo de secretos, el siguiente paso natural es revisar [CONNECTORS_OPERATIONAL_MODEL.md](./CONNECTORS_OPERATIONAL_MODEL.md) junto con el equipo de plataforma.
