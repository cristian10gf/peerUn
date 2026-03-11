# Evalia — Propuesta Funcional y Técnica Unificada

> **Equipo:** Cristian · Sandro · Jorge · Flavio
>
> **Figma:** https://www.figma.com/design/DDNofweJTAejsv44DZ1akb/Untitled?node-id=1-801&t=LxzPnaJQcuQtXxtO-1
>
> **Proyecto:** Plataforma móvil de evaluación entre compañeros para trabajo colaborativo universitario
> **Fecha:** 25 de febrero de 2026
> **Tecnologías objetivo:** Flutter · GetX · Clean Architecture · Roble (Auth/DB) · n8n · Brightspace

---

## Tabla de Contenidos

1. [Descripción de la propuesta](#1-descripción-de-la-propuesta)
2. [Análisis de competencia](#2-análisis-de-competencia)
3. [Objetivo del sistema](#3-objetivo-del-sistema)
4. [Alcance y supuestos](#4-alcance-y-supuestos)
5. [Experiencia de usuario (UX)](#5-experiencia-de-usuario-ux)
   - 5.1 [Flujo del Profesor](#51-flujo-del-profesor)
   - 5.2 [Flujo del Estudiante](#52-flujo-del-estudiante)
6. [Funcionalidades principales](#6-funcionalidades-principales)
7. [Flujo de evaluación detallado](#7-flujo-de-evaluación-detallado)
8. [Autenticación y registro](#8-autenticación-y-registro)
9. [Arquitectura del sistema](#9-arquitectura-del-sistema)
10. [Integración con n8n y Brightspace](#10-integración-con-n8n-y-brightspace)
11. [Decisiones de diseño](#11-decisiones-de-diseño)
12. [Modelo de datos](#12-modelo-de-datos)
13. [KPIs y métricas de éxito](#13-kpis-y-métricas-de-éxito)
14. [Limitaciones y evolución](#14-limitaciones-y-evolución)
15. [Referencias visuales](#15-referencias-visuales)

---

## 1. Descripción de la propuesta

**Evalia** es una plataforma móvil centrada en la evaluación entre compañeros dentro de cursos universitarios con trabajo colaborativo. 

El sistema define dos actores principales con interfaces completamente separadas pero que comparten componentes reutilizables:

- **Profesor:** crea y gestiona evaluaciones, importa grupos desde Brightspace, monitorea el progreso y consulta resultados analíticos.
- **Estudiante:** evalúa a sus compañeros de equipo de forma anónima, consulta sus resultados y accede a recursos de mejora colaborativa.

La propuesta se rige por tres principios de diseño:

- **Claridad:** cada usuario entiende rápidamente qué hacer, cómo y por qué es importante.
- **Rapidez:** flujos minimalistas que reducen fricción mediante scroll guiado y acciones rápidas.
- **Responsabilidad:** trazabilidad de señales críticas sin afectar el cálculo académico de nota válida.

---

## 2. Análisis de competencia

Evalia se posiciona en un nicho específico: evaluación entre pares integrada al LMS universitario, con experiencia nativa móvil y automatización sin intervención técnica del docente.

| Plataforma | Tipo | Evaluación entre pares | Integración LMS | App móvil nativa | Automatización |
|---|---|---|---|---|---|
| **Evalia** | Universitaria | ✅ Estructurada | ✅ Brightspace | ✅ Flutter | ✅ n8n |
| Buddycheck | SaaS universitario | ✅ Sí | ✅ Parcial | ❌ Web | ❌ Manual |
| CATME | Investigación | ✅ Sí | ❌ No | ❌ Web | ❌ Manual |
| Peergrade | Educativa general | ✅ Sí | ⚠️ Limitada | ❌ Web | ❌ Manual |
| Canvas Peer Review | LMS integrado | ⚠️ Básica | ✅ Canvas | ❌ Web | ⚠️ Parcial |
| Google Forms + Sheets | Genérico | ⚠️ Manual | ❌ No | ❌ Web | ❌ Manual |

### Ventajas diferenciales de Evalia

1. **Integración nativa con Brightspace** como fuente de verdad de cursos, grupos y ventanas académicas.
2. **Orquestación automática via n8n**: sincronización, activación y cierre de evaluaciones sin intervención docente.
3. **Experiencia móvil first**: diseñada para el contexto real del estudiante universitario.
4. **Señales de alerta (0/1)** separadas del cálculo académico, para detección temprana de conflictos de equipo.
5. **Perfil dinámico** con retroalimentación emocional y recursos formativos integrados.

---

## 3. Objetivo del sistema

Construir una solución móvil que permita evaluar el desempeño colaborativo entre pares de forma estructurada, transparente y accionable, completamente alineada con la operación académica existente en Brightspace.

### Objetivos específicos

1. Incrementar la participación estudiantil en procesos de evaluación entre pares.
2. Reducir la carga operativa docente mediante automatización vía n8n.
3. Mostrar resultados con promedio ponderado y detalle por compañero, con reglas de visibilidad pública o privada.
4. Reforzar competencias blandas mediante contenido de apoyo integrado en la app.
5. Proveer al profesor analítica útil: por semestre, por curso, por evaluación, por grupo y por estudiante.

---

## 4. Alcance y supuestos

### En alcance

- App móvil con dos interfaces separadas: **profesor** y **estudiante**.
- Componentes UI reutilizables compartidos entre ambas interfaces.
- Consulta y gestión de cursos del semestre activo.
- Importación de grupos desde Brightspace (CSV o API).
- Motor de evaluación entre pares sin autoevaluación.
- Visualización de resultados con múltiples niveles de agregación.
- Perfil dinámico del estudiante con retroalimentación adaptada.
- Integración operativa con Brightspace y orquestación automática via n8n.

### Fuera de alcance (v1)

- Módulo de creación manual de grupos dentro de la app.
- Analítica avanzada de sesgo y outliers (planificada en v2).
- Microcontenidos adaptativos por perfil de desempeño.

### Supuestos operativos

- Brightspace es la fuente de verdad para cursos, categorías y composición de grupos.
- n8n orquesta sincronizaciones, activaciones y cierre de evaluaciones.
- Roble provee autenticación institucional (SSO) y persistencia de resultados.
- Los profesores usan Brightspace activamente para la gestión académica del curso.

---

## 5. Experiencia de usuario (UX)

La arquitectura de navegación separa completamente las experiencias de **profesor** y **estudiante**, mientras comparte un sistema de componentes comunes (botones, tarjetas de curso, modales de confirmación, estados vacíos, loaders, etc.).

---

### 5.1 Flujo del Profesor

#### P1 · Login
- Pantalla de acceso con correo institucional y contraseña.
- Opción de autenticación via SSO con Roble.
- Opción alternativa: flujo de registro manual para profesores nuevos.

#### P2 · Mis Cursos
- Lista de cursos activos del semestre (ej. "Mobile Dev", "Bases de Datos II", "Redes").
- Estado visual por curso: activo, cerrado, sin actividad.
- Indicador de grupos y estudiantes por curso.
- Acceso rápido a invitar usuarios al curso.

#### P3 · Importar Grupos desde Brightspace
- Vista de categorías importables desde Brightspace (ej. "Proyecto Final", "Talleres", "Exposiciones").
- Selección múltiple de categorías con checkbox.
- Confirmación con resumen: cantidad de grupos y estudiantes por categoría.
- Nota informativa: "Las actualizaciones en Brightspace se sincronizan automáticamente."

#### P4 · Crear Evaluación
- Nombre de la evaluación (ej. "Evaluación Sprint 2").
- Selección de categoría de grupos objetivo.
- Ventana de tiempo configurable (en horas).
- Visibilidad de resultados: **Pública** o **Privada**.
- Criterios incluidos: Puntualidad · Aportes · Compromiso · Actitud.
- Escala: 2.0 · 3.0 · 4.0 · 5.0 por criterio.
- Botón "Crear y activar" con confirmación.

#### P5 · Monitoreo
- Vista en tiempo real del progreso de respuestas por grupo.
- Indicador numérico: respuestas recibidas / total esperado por grupo.
- Badge de confirmación "Evaluación activada" y "Estudiantes notificados".
- Botón "Enviar recordatorio" para grupos con baja participación.
- Contador de evaluaciones pendientes de cerrar.

#### P6 · Resultados
- Promedio general de actividad destacado visualmente (ej. 4.1).
- Pestañas de vista: **General · Grupo · Estudiante · Criterio**.
- Resultados por grupo con barra de progreso comparativa.
- Resultados por criterio: Puntualidad, Aportes, Compromiso, Actitud.
- Niveles de agregación disponibles: por semestre → por curso → por evaluación → por grupo → por estudiante.

---

### 5.2 Flujo del Estudiante

#### E1 · Login
- Acceso con correo institucional y contraseña.
- Autenticación SSO con Roble.
- La cuenta se crea cuando el profesor carga el grupo o vía CSV; se envía correo de confirmación para activarla.

#### E2 · Cursos Inscritos
- Lista de cursos del semestre con grupo y profesor asignado.
- Badge de evaluación pendiente cuando hay actividad activa.
- Estado por curso: evaluación pendiente, sin actividad.
- Sección inferior de **Recursos para ser mejor compañero** (lecturas, juegos, material interactivo).

#### E3 · Acceso a Evaluación
- Detalle de la evaluación activa: nombre, tiempo restante, grupo.
- Mensaje contextual: "Evalúa a cada compañero de tu grupo. No hay autoevaluación. Tus respuestas son anónimas."
- Criterios listados: Puntualidad · Aportes al equipo · Compromiso · Actitud.
- Escala visible: 2 · 3 · 4 · 5.
- Botón "Comenzar evaluación".

#### E4 · Evaluar Compañero
- Encabezado con nombre y avatar del compañero (ej. "Carlos Ruiz — Compañero 1 de 7").
- Barra de progreso del flujo de evaluación.
- Por cada criterio: selector de escala con etiquetas contextuales (Insuf. / Niv. / Bien / Exc.).
- Opacidad reducida en preguntas no activas para foco visual.
- Scroll automático al responder cada criterio.
- Escala extendida: 0 y 1 para señales de alerta (no calculan nota).
- Atajo "Fue un excelente compañero" → asigna 5 a todos los criterios.
- Botón "Siguiente →" al completar cada compañero.

#### E5 · Resumen Final y Confirmación
- Lista de todos los compañeros evaluados con promedio asignado y checkmark de completado.
- Recordatorio: "Tu evaluación es anónima. Sin autoevaluación incluida."
- Botón "Enviar evaluación".

#### E6 · Mis Resultados
- Confirmación de envío con ícono de éxito y mensaje "¡Evaluación enviada!".
- Promedio obtenido en la evaluación (ej. 4.3).
- Desempeño por criterio con barras comparativas.
- Promedio del grupo como referencia contextual.
- Indicación de disponibilidad de resultados públicos (según visibilidad configurada por profesor).

---

## 6. Funcionalidades principales

### Para el Profesor

1. **Autenticación** institucional (SSO Roble) o manual con confirmación por correo.
2. **Registro de profesor** con validación institucional.
3. **Gestión de cursos**: listado, detalle, e invitación de usuarios.
4. **Importación de grupos** desde Brightspace por categorías seleccionables.
5. **Creación de evaluaciones** con criterios, escala, ventana de tiempo y visibilidad.
6. **Monitoreo en tiempo real** del progreso de respuestas con recordatorios.
7. **Analítica de resultados** multi-nivel: semestre, curso, evaluación, grupo, estudiante, criterio.

### Para el Estudiante

1. **Autenticación** SSO Roble o activación por correo (cuenta creada por el profesor).
2. **Consulta de cursos** con estados de evaluación claros.
3. **Motor de evaluación entre pares** sin autoevaluación, con anonimato garantizado.
4. **Escala extendida con señales 0/1**: separadas del cálculo académico, registradas para análisis institucional.
5. **Atajo de excelencia**: asigna 5 a todos los criterios del compañero actual.
6. **Resultados personales** con promedio ponderado y detalle por criterio.
7. **Recursos de aprendizaje colaborativo** integrados en la sección de cursos.
8. **Perfil dinámico** con retroalimentación visual adaptada al rendimiento.
9. **Sección de ayuda** accesible desde ajustes.

### Componentes Compartidos (Profesor + Estudiante)

- Sistema de autenticación y sesión.
- Tarjetas de curso reutilizables.
- Modales de confirmación y estados vacíos.
- Sistema de notificaciones push (apertura, cierre, recordatorios).
- Navegación por pestañas con estructura adaptada por rol.
- Componente de escala de evaluación.

---

## 7. Flujo de evaluación detallado

### Regla de cálculo

- El promedio ponderado considera únicamente calificaciones válidas (2–5).
- Los valores 0 y 1 se registran como señales de alerta para análisis institucional y seguimiento del docente.
- No hay autoevaluación en ningún caso.

### Paso a paso

1. El estudiante accede al curso y selecciona la evaluación activa.
2. Se muestra el primer compañero elegible con su nombre y avatar.
3. Las preguntas se presentan con opacidad reducida; solo la pregunta activa tiene foco visual completo.
4. Al responder, el sistema hace scroll automático hacia el siguiente criterio.
5. El usuario puede:
   - Asignar valores de 2 a 5 para nota académica válida.
   - Usar 0 o 1 para reportar una señal o denuncia (sin impacto en nota).
   - Activar "Fue un excelente compañero" para completar con 5 de forma masiva.
6. Al finalizar cada compañero, se confirma el bloque y se avanza al siguiente.
7. Al completar todos los compañeros, se muestra resumen final antes del envío.
8. Al enviar, se registra la trazabilidad de entrega y se muestran resultados inmediatos.

---

## 8. Autenticación y registro

El sistema contempla dos modalidades de acceso, adaptadas al rol del usuario.

### Opción A: Autenticación institucional via SSO (Roble)

- Login directo con credenciales institucionales (correo + contraseña Roble).
- No requiere registro previo en Evalia.
- Disponible para profesores y estudiantes con cuenta activa en Roble.
- Flujo: `App Evalia → Redirect a Roble SSO → Token de sesión → App Evalia`.

### Opción B: Registro y activación manual (orquestado por n8n)

**Flujo del Profesor:**
1. El profesor se registra con correo institucional y contraseña en Evalia.
2. n8n intercepta el evento de registro y envía un correo de confirmación.
3. El profesor confirma su correo → cuenta activada → acceso completo.

**Flujo del Estudiante:**
1. El profesor carga el grupo (CSV o importación desde Brightspace).
2. n8n detecta los nuevos usuarios y crea sus cuentas automáticamente en Roble.
3. Cada estudiante recibe un correo con enlace de activación y credenciales temporales.
4. El estudiante activa su cuenta → acceso al flujo de evaluación.

### Resumen comparativo

| Característica | SSO Roble | Manual + n8n |
|---|---|---|
| Fricción de acceso | Mínima | Media (1 paso de activación) |
| Dependencia técnica | Alta (Roble disponible) | Baja (n8n gestiona) |
| Control institucional | Total | Delegado a n8n |
| Escalabilidad | Alta | Alta |
| Ideal para | Institución con Roble activo | Piloto / rollout gradual |

---

## 9. Arquitectura del sistema

Se adopta **Clean Architecture** para separar claramente UI, dominio y datos, con módulos independientes por actor y una capa de componentes compartidos.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Aplicación Flutter                          │
│                                                                     │
│  ┌──────────────────────┐      ┌──────────────────────────────────┐ │
│  │   UI / Profesor       │      │   UI / Estudiante                │ │
│  │  P1 Login · P2 Cursos │      │  E1 Login · E2 Cursos            │ │
│  │  P3 Grupos · P4 Eval  │      │  E3 Acceso · E4 Evaluar          │ │
│  │  P5 Monitor · P6 Res  │      │  E5 Resumen · E6 Resultados      │ │
│  └──────────┬───────────┘      └────────────────┬─────────────────┘ │
│             │                                   │                   │
│  ┌──────────┴───────────────────────────────────┴─────────────────┐ │
│  │              Componentes Compartidos                            │ │
│  │  TarjetaCurso · EscalaEvaluacion · ModalConfirmacion           │ │
│  │  NotificacionPush · NavegacionPorPestanas · EstadoVacio        │ │
│  └────────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────┤
│  Presentación (GetX)                                                │
│  Controllers · Estado reactivo · Rutas · Bindings                   │
├─────────────────────────────────────────────────────────────────────┤
│  Dominio                                                            │
│  Casos de uso: iniciar evaluación, calificar, calcular promedios    │
│  Reglas: visibilidad pública/privada · exclusión 0/1 · anonimato    │
├─────────────────────────────────────────────────────────────────────┤
│  Datos                                                              │
│  Repositorios · Mappers · Fuentes remotas / locales                 │
├─────────────────────────────────────────────────────────────────────┤
│  Infraestructura externa                                            │
│  Roble (Auth + DB) · Brightspace (LMS) · n8n (automatización)       │
└─────────────────────────────────────────────────────────────────────┘
```

### Módulos lógicos

| Módulo | Responsabilidad | Actor |
|---|---|---|
| `AuthModule` | Login, sesión, registro, activación | Compartido |
| `CourseModule` | Listado y detalle de cursos | Compartido |
| `GroupModule` | Importación y gestión de grupos | Profesor |
| `EvaluationModule` | Creación, cuestionario, validaciones, envío | Compartido |
| `MonitoringModule` | Progreso en tiempo real, recordatorios | Profesor |
| `ResultsModule` | Promedios ponderados y analítica multi-nivel | Compartido |
| `ProfileModule` | Visuales dinámicas por rendimiento | Estudiante |
| `ResourcesModule` | Contenido para fortalecer trabajo en equipo | Estudiante |
| `NotificationModule` | Push, recordatorios, confirmaciones | Compartido |

---

## 10. Integración con n8n y Brightspace

### 10.1 Rol de Brightspace

- Fuente oficial de cursos, grupos y membresías estudiantiles.
- Punto de referencia para ventanas académicas y estructura de actividades.
- Provee datos de categorías de grupos importables (Proyecto Final, Talleres, Exposiciones, etc.).

### 10.2 Rol de n8n

n8n actúa como capa de orquestación sin exponer complejidad al usuario final:

| Workflow | Disparador | Acción |
|---|---|---|
| Sincronización de cursos | Programado (diario) | Actualiza cursos y grupos desde Brightspace en Roble |
| Activación de evaluación | Evento: profesor activa | Notifica a todos los estudiantes del grupo |
| Recordatorio de participación | Programado (cada N horas) | Envía push a estudiantes sin completar |
| Cierre automático de ventana | Fecha/hora configurada | Cierra evaluación y calcula promedios finales |
| Publicación de visibilidad | Post-cierre | Publica resultados según configuración pública/privada |
| Registro de estudiante | Evento: nuevo usuario en CSV | Crea cuenta en Roble y envía correo de activación |
| Registro de profesor | Evento: nuevo registro | Envía correo de confirmación institucional |

### 10.3 Beneficios

- Cero carga manual operativa para docentes.
- Desalineación mínima entre app y LMS.
- Escalabilidad para múltiples cursos y cohortes sin panel admin adicional.
- Separación de responsabilidades: el profesor diseña la evaluación, n8n la gestiona operativamente.

---

## 11. Decisiones de diseño

1. **Enfoque mobile-first**: diseñada para el contexto estudiantil universitario móvil.
2. **Dos interfaces separadas, un codebase**: profesor y estudiante con UX propia pero componentes Flutter reutilizables.
3. **Foco visual por opacidad**: aumenta precisión de respuesta pregunta a pregunta, reduce sesgo de atención.
4. **Atajo de excelencia**: acelera evaluaciones homogéneas positivas sin sacrificar granularidad.
5. **Señales 0/1 como eventos separados**: preserva integridad del cálculo académico y habilita seguimiento institucional.
6. **Perfil emocionalmente inteligente**: feedback visual motivador para mejorar, no para castigar.
7. **Recursos integrados en cursos**: la app es herramienta formativa, no solo calificadora.
8. **Sin app admin docente frontend**: la operación se delega a automatizaciones n8n + Brightspace.
9. **Anonimato garantizado en evaluación**: el estudiante evalúa con seguridad; el nombre del evaluador no se expone.
10. **Nombre "Evalia"**: evoca evaluación + IA, claro, memorizable y diferenciador en contexto universitario.

---

## 12. Modelo de datos

```
Usuario
├── id
├── nombre
├── email
├── rol (student | professor)
├── promedioGeneral         // solo estudiante
└── cuentaActivada

Curso
├── id
├── nombre
├── periodo
├── profesorId
└── promedioPonderado

Grupo
├── id
├── cursoId
├── nombre
├── categoria               // importada desde Brightspace
└── miembros[]              // lista de estudianteIds

Evaluacion
├── id
├── cursoId
├── nombre
├── visibilidad             // publica | privada
├── criterios[]             // lista de nombres de criterio
├── escala                  // [2, 3, 4, 5]
├── fechaApertura
├── fechaCierre
└── estado                  // activa | cerrada | pendiente

Respuesta
├── id
├── evaluacionId
├── evaluadorId
├── evaluadoId
├── criterio
├── valor                   // 0..5
└── esSenal                 // true si valor 0 o 1

ResultadoAgregado
├── id
├── evaluacionId
├── estudianteId
├── promedioPonderado
├── detallesPorCriterio{}
└── nivelAgregacion         // evaluacion | curso | semestre
```

---

## 13. KPIs y métricas de éxito

| KPI | Descripción | Meta v1 |
|---|---|---|
| Tasa de participación | % de estudiantes que completan la evaluación dentro de la ventana | > 85% |
| Tiempo de finalización | Duración media por evaluación completa | < 8 min |
| Adopción docente | % de profesores que crean al menos 1 evaluación por semestre | > 70% |
| Cobertura de recursos | % de usuarios que acceden al contenido formativo | > 40% |
| Distribución de señales | Trazabilidad de alertas 0/1 por curso y equipo | Registro completo |
| Consistencia de evaluación | Variación de calificaciones entre miembros de un mismo grupo | Monitoreable |
| NPS interno | Net Promoter Score de profesores y estudiantes al final del semestre | > 40 |

---

## 14. Limitaciones y evolución

### Limitaciones actuales (v1)

- Sin panel de administración docente en frontend (delegado a n8n).
- Dependencia de la calidad y frecuencia de sincronización con el LMS.
- La interpretación de señales 0/1 requiere protocolo institucional de seguimiento.
- Sin módulo de autoevaluación (fuera de alcance por decisión de diseño).

### Evolución sugerida (v2 y v3)

| Versión | Funcionalidad |
|---|---|
| v2 | Analítica avanzada de sesgo y outliers por grupo |
| v2 | Módulo de recomendaciones automáticas por criterio de bajo rendimiento |
| v2 | Panel docente simplificado en frontend |
| v3 | Microcontenidos adaptativos según perfil de desempeño |
| v3 | Integración con otros LMS (Canvas, Moodle) |
| v3 | Módulo de autoevaluación opcional configurable por el profesor |
| v3 | Dashboard institucional para coordinadores y decanos |

---

## 15. Referencias visuales

### Flujo del Profesor

| Pantalla | Descripción |
|---|---|
| P1 · Login | Acceso institucional o SSO Roble |
| P2 · Mis Cursos | Lista de cursos activos del semestre |
| P3 · Importar Grupos | Selección de categorías desde Brightspace |
| P4 · Crear Evaluación | Configuración de criterios, escala, tiempo y visibilidad |
| P5 · Monitoreo | Progreso en tiempo real, recordatorios por grupo |
| P6 · Resultados | Analítica multi-nivel: general, grupo, estudiante, criterio |

### Flujo del Estudiante

| Pantalla | Descripción |
|---|---|
| E1 · Login | Acceso institucional o activación por correo |
| E2 · Cursos Inscritos | Cursos activos, estados de evaluación, recursos formativos |
| E3 · Acceso a Evaluación | Detalle de evaluación activa, reglas de anonimato |
| E4 · Evaluar Compañero | Escala por criterio, foco visual, atajo de excelencia |
| E5 · Resumen Final | Confirmación de respuestas antes del envío |
| E6 · Mis Resultados | Promedio personal, desempeño por criterio, comparativa grupal |

---

## Conclusión

Evalia unifica los aportes del equipo en una propuesta técnica y funcional coherente: la base de arquitectura limpia de **Cristian**, la identidad visual y el nombre propuestos por **Sandro**, las funcionalidades de n8n y el motor de evaluación de **Jorge**, y el análisis diferencial de competencia de **Flavio**.

El resultado es una plataforma móvil que cubre el ciclo completo de la evaluación entre pares — **motivación → configuración → evaluación → resultado → reflexión** — con una arquitectura que escala, una integración que reduce fricción operativa, y una experiencia que prioriza la participación y la percepción de justicia del proceso académico.
