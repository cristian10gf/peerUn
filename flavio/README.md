# PeerEval Dúo — Propuesta de Solución

> **Estudiante:** Flavio Arregoces    
> **Proyecto:** Aplicación móvil de evaluación entre pares para trabajo colaborativo universitario  
> **Fecha:** 22 de febrero de 2026  
> **Tecnologías definidas:** 

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![GetX](https://img.shields.io/badge/GetX-8A2BE2?style=for-the-badge)
![Clean Architecture](https://img.shields.io/badge/Clean_Architecture-4CAF50?style=for-the-badge)
![Roble](https://img.shields.io/badge/Roble-Auth-FF6B35?style=for-the-badge)
![Brightspace](https://img.shields.io/badge/Brightspace-Integration-0072C6?style=for-the-badge)


---

## Tabla de Contenidos

1. [Referentes Analizados](#1-referentes-analizados)
2. [Composición y Diseño de la Solución](#2-composición-y-diseño-de-la-solución)
3. [Flujo Funcional Detallado](#3-flujo-funcional-detallado)
4. [Justificación de la Propuesta](#4-justificación-de-la-propuesta)

---

## 1. Referentes Analizados

### 1.1 WebPA (Loughborough University)

**Descripción general**

WebPA es un sistema open source de evaluación entre pares desarrollado en la Universidad de Loughborough, Reino Unido. Su característica más notable es el algoritmo WebPA, que toma la nota grupal y la redistribuye individualmente según las evaluaciones recibidas de los compañeros. Ha sido adoptado por universidades del Reino Unido y Australia y su código fuente está disponible públicamente.

**Gestión de grupos**

Los grupos se crean en WebPA manualmente o importando un archivo CSV. No tiene integración con ningún LMS. El administrador del sistema crea cursos y el instructor gestiona grupos dentro de cada curso. No hay sincronización automática con plataformas externas.

**Proceso de evaluación**

1. El instructor crea una evaluación y define los grupos participantes y la ventana de tiempo.
2. Los estudiantes acceden mediante usuario y contraseña y evalúan a sus compañeros de grupo.
3. El sistema calcula el factor WebPA para cada estudiante y lo aplica sobre la nota grupal para obtener la nota individual.

**Criterios de evaluación**

El instructor define los criterios libremente (entre 1 y 10 criterios). Cada uno se puntúa en una escala de 0 a 100. No impone descriptores conductuales; los define el instructor o se dejan en blanco.

**Visualización de resultados**

- *Instructor:* factores WebPA por estudiante, puntajes por criterio, exportación CSV.
- *Estudiante:* puede ver su factor WebPA y el promedio recibido por criterio si el instructor lo permite.

**Limitaciones relevantes**

- Sin app móvil nativa.
- Sin integración con Brightspace ni ningún LMS.
- El algoritmo WebPA asume que la nota del grupo ya está definida; no funciona como evaluación independiente.
- Interfaz visualmente anticuada.
- Sin notificaciones activas; el estudiante solo se entera si entra a la plataforma.
- Sin soporte en español.

---

### 1.2 FeedbackFruits

**Descripción general**

FeedbackFruits es una plataforma EdTech neerlandesa (Ámsterdam) que ofrece un conjunto de herramientas de aprendizaje activo, incluyendo evaluación entre pares, retroalimentación sobre vídeos y autoevaluación. Se integra con los principales LMS mediante LTI 1.3. Su enfoque es facilitar al máximo la adopción por parte del instructor, con una configuración guiada paso a paso y plantillas predefinidas.

**Gestión de grupos**

FeedbackFruits se integra directamente con los grupos existentes en el LMS vía LTI. Si el instructor tiene grupos en Canvas, Brightspace o Moodle, FeedbackFruits los importa automáticamente sin pasos adicionales. Cualquier cambio de composición grupal en el LMS se refleja automáticamente.

**Proceso de evaluación**

1. El instructor configura la actividad directamente desde el LMS (como si fuera una tarea más del curso).
2. Los estudiantes evalúan a sus compañeros según los criterios definidos.
3. FeedbackFruits envía recordatorios automáticos por correo antes del cierre.
4. El instructor puede liberar los resultados cuando lo decida.

**Criterios de evaluación**

FeedbackFruits ofrece plantillas predefinidas de criterios para trabajo colaborativo (similares a los del enunciado: puntualidad, contribución, comunicación, etc.) y permite al instructor modificarlas. La escala es configurable: numérica (1-5, 1-10) o cualitativa.

**Visualización de resultados**

- *Instructor:* dashboard con tasas de participación, promedios por criterio, comparativo entre grupos.
- *Estudiante:* retroalimentación recibida con comentarios de los evaluadores (con control de anonimato).

**Limitaciones relevantes**

- Es de pago; requiere licencia institucional con Brightspace.
- Sin app móvil nativa; funciona embebido en el LMS a través del navegador.
- La experiencia del usuario depende de la calidad de la integración LTI de la institución.
- Sin soporte completo en español.

---

### 1.3 Peerceptiv

**Descripción general**

Peerceptiv es una plataforma de evaluación entre pares desarrollada en la Universidad Carnegie Mellon (CMU). Originalmente se llamaba Peergrader y fue creada como proyecto de investigación académica. En 2017 se convirtió en una empresa independiente (Peerceptiv Inc., Pittsburgh, PA). Está diseñada principalmente para evaluación de trabajos escritos, pero incluye módulos de evaluación de desempeño colaborativo.

**Gestión de grupos**

Los grupos se gestionan dentro de Peerceptiv. Permite importar listas de estudiantes desde CSV y tiene integración LTI con Canvas. No tiene integración oficial con Brightspace.

**Proceso de evaluación**

Peerceptiv tiene un enfoque de *calibración*: antes de evaluar a compañeros, los estudiantes practican evaluando ejemplos de referencia. Esto mejora la consistencia y reduce el sesgo. El instructor define cuántas evaluaciones debe hacer cada estudiante.

**Criterios de evaluación**

Los criterios los define el instructor. Peerceptiv permite criterios cuantitativos (escala numérica) y cualitativos (rubric con descriptores). También permite la evaluación anónima o identificada según decisión del instructor.

**Visualización de resultados**

- *Instructor:* reportes de participación, distribución de puntajes, detección de evaluadores inconsistentes.
- *Estudiante:* retroalimentación recibida, puntaje promedio y comparativo con la media del grupo.

**Limitaciones relevantes**

- Sin app móvil nativa.
- Sin integración con Brightspace.
- El modelo de calibración es valioso pero añade pasos al flujo que pueden resultar complejos en el contexto del proyecto.
- Es de pago.
- Sin soporte en español.

---

### Tabla comparativa de referentes

| Característica | WebPA | FeedbackFruits | Peerceptiv |
|---|:---:|:---:|:---:|
| App móvil nativa | ❌ | ❌ | ❌ |
| Integración con Brightspace | ❌ | ✅ LTI | ❌ |
| Sin autoevaluación por defecto | ✅ | ✅ | ✅ |
| Criterios configurables | ✅ Libre | ✅ Plantillas | ✅ Libre |
| Visibilidad pública/privada | ✅ | ✅ | ✅ |
| Ventana de tiempo configurable | ✅ | ✅ | ✅ |
| Notificaciones push | ❌ | ❌ Email | ❌ Email |
| Roles diferenciados (UI distinta) | ✅ | ✅ | ✅ |
| Open source | ✅ | ❌ | ❌ |
| Disponible en español | ❌ | ⚠️ Parcial | ❌ |
| Costo | 🆓 Gratuito | 💰 Pago | 💰 Pago |

> **Oportunidad identificada:** FeedbackFruits es el único que se integra con Brightspace, pero requiere licencia institucional y no tiene app móvil. Los tres muestran que la separación de experiencias por rol (instructor vs. estudiante) mejora la usabilidad. PeerEval Dúo lleva esa separación al extremo: dos apps completamente independientes, con identidades visuales distintas y código de presentación sin cruce de lógica entre roles.

---

## 2. Composición y Diseño de la Solución

### 2.1 Decisión de arquitectura: dos apps Flutter independientes con lógica de dominio compartida

**Se proponen dos aplicaciones Flutter separadas:** `peereval_teacher` para docentes y `peereval_student` para estudiantes, organizadas en un monorepo con un package Dart compartido (`peereval_core`) que contiene la capa de dominio y de datos. Cada app implementa únicamente su capa de presentación.

**Alternativas descartadas:**

| Alternativa | Razón de descarte |
|---|---|
| Una sola app con roles | La UX óptima para cada rol implica decisiones de diseño que se contradicen: el docente necesita densidad de información, el estudiante necesita simplicidad extrema. Mezclarlos en una sola app obliga a compromisos que perjudican a los dos. |
| Dos apps sin código compartido | Duplica la lógica de negocio: entidades, repositorios y casos de uso tendrían que mantenerse en dos lugares distintos. Cualquier corrección de bug requeriría hacerla dos veces. |
| App + plataforma web | La gestión en web está justificada solo si hay datos de un volumen que no puede mostrarse cómodamente en móvil. Para el alcance del proyecto, la app del docente es suficiente. |

**Justificación:**
- WebPA y FeedbackFruits tienen interfaces deliberadamente distintas para instructor y estudiante dentro del mismo sistema. PeerEval Dúo lleva esa separación al nivel de producto, lo que permite diseñar cada app pensando exclusivamente en su usuario.
- Con dos apps separadas, la app del estudiante no contiene físicamente el código de las funciones de administración. No hay lógica condicional que proteger; el código simplemente no está.
- El package `peereval_core` evita duplicación: entidades, casos de uso y repositorios se escriben una sola vez y los dos proyectos los consumen.

---

### 2.2 Arquitectura técnica

```
peereval_duo/  (monorepo)
├── packages/
│   └── peereval_core/          ← package Dart compartido
│       ├── domain/
│       │   ├── entities/       ← Usuario, Curso, Grupo, Evaluacion...
│       │   ├── usecases/       ← casos de uso por rol
│       │   └── repositories/   ← interfaces (contratos)
│       └── data/
│           ├── models/         ← JSON serializable
│           ├── datasources/    ← Roble API, Brightspace API, caché local
│           └── repositories/   ← implementaciones
│
├── apps/
│   ├── peereval_teacher/       ← Flutter app (docentes)
│   │   └── presentation/
│   │       ├── dashboard/
│   │       ├── courses/
│   │       ├── groups/
│   │       ├── assessments/
│   │       └── results/
│   │
│   └── peereval_student/       ← Flutter app (estudiantes)
│       └── presentation/
│           ├── courses/
│           ├── evaluation/
│           └── results/
│
└── melos.yaml                  ← gestión del monorepo con Melos
```

| Capa | Responsabilidad | Ubicación |
|---|---|---|
| Presentación | Widgets, controllers GetX, rutas | Cada app por separado |
| Dominio | Entidades, casos de uso, interfaces | `peereval_core` |
| Datos | Modelos JSON, repositorios, datasources | `peereval_core` |

---



## 3. Flujo Funcional Detallado

### 3.1 Flujo del docente (peereval_teacher)

```
ONBOARDING
    │
    ▼
[Login con Roble — app de docente]
    │  Credenciales → JWT con rol = "teacher"
    │  Si el JWT devuelve rol = "student": error → descargar peereval_student
    ▼
[Crear curso]
    │  Nombre → guardado en Roble DB
    │  Se genera código de invitación automáticamente
    ▼
[Importar grupos desde Brightspace]
    │  Pantalla "Importar grupos" → trae categorías del curso vía API
    │  Tabla de vista previa: nombre, código Brightspace, miembros
    │  El docente selecciona las categorías a importar y confirma
    │  Si hay cambios posteriores → re-importar; si hay eval. activa → diferir
    ▼
[Crear evaluación]
    │  1. Nombre de la actividad
    │  2. Categoría de grupo objetivo
    │  3. Duración (horas)
    │  4. Visibilidad: Pública o Privada
    │  Confirmar → push a todos los estudiantes de los grupos seleccionados
    ▼
[Monitorear]
    │  Barra de completitud en tiempo real: X/N completadas
    ▼
[Ver resultados]
    ├── Promedio por actividad (todos los grupos)
    ├── Promedio por grupo (entre actividades)
    ├── Promedio por estudiante (entre actividades)
    └── Detalle: grupo → estudiante → puntaje por criterio
```

---

### 3.2 Flujo del estudiante (peereval_student)

```
ONBOARDING
    │
    ▼
[Login con Roble — app de estudiante]
    │  JWT con rol = "student"
    │  Si el JWT devuelve rol = "teacher": error → descargar peereval_teacher
    │  Ingresar código de invitación del docente → unirse al curso
    ▼
[Ver mis cursos y mi grupo]
    │  Lista de cursos con nombre del grupo y compañeros
    ▼
[Notificación push]
    │  "Nueva evaluación activa: [nombre] — Tienes [X] horas"
    ▼
[Realizar evaluación]
    │
    │  Para cada compañero (sin autoevaluación):
    │  ┌────────────────────────────────────────────────────────┐
    │  │  CRITERIO: CONTRIBUCIONES                               │
    │  │  ○ 2.0 – Necesita Mejorar                              │
    │  │      "Estuvo en todo momento como observador..."       │
    │  │  ○ 3.0 – Adecuado                                      │
    │  │      "En algunas ocasiones participó..."               │
    │  │  ○ 4.0 – Bueno                                         │
    │  │      "Hizo varios aportes; puede ser más propositivo"  │
    │  │  ● 5.0 – Excelente                                     │
    │  │      "Sus aportes enriquecieron el trabajo del equipo" │
    │  │                                                         │
    │  │  [PUNTUALIDAD]  [COMPROMISO]  [ACTITUD]                │
    │  └────────────────────────────────────────────────────────┘
    │  Progreso: compañero X de N → confirmar al finalizar todos
    ▼
[Ver resultados — solo si evaluación es Pública]
    │  Promedio recibido por criterio
    └── Promedio general
```

---

### 3.3 Mapa de navegación

```
peereval_teacher
├── /login
├── /dashboard              → resumen de cursos y evaluaciones activas
├── /courses/:id
│   ├── /groups             → importar y sincronizar desde Brightspace
│   ├── /assessments
│   │   ├── /new            → crear evaluación
│   │   └── /:assId/results → resultados por nivel de detalle
│   └── /invite             → código de invitación del curso
└── /profile

peereval_student
├── /login                  → código de invitación al registrarse
├── /home                   → mis cursos y evaluaciones activas
├── /courses/:id
│   ├── /my-group           → mis compañeros
│   └── /assessments
│       └── /:assId/evaluate → formulario peer-to-peer
└── /profile
```

---

## 4. Justificación de la Propuesta

### 4.1 Basada en referentes

**WebPA** demuestra que la separación de interfaces por rol mejora la usabilidad: el instructor ve datos densos y el estudiante solo ve su formulario. También introduce la idea de redistribución de nota según evaluación grupal, que muestra que las instituciones confían en este tipo de herramientas para decisiones de calificación reales. La debilidad de WebPA es que no tiene app móvil y que su algoritmo depende de que ya exista una nota grupal; PeerEval Dúo resuelve esto operando como herramienta independiente de calificación.

**FeedbackFruits** es el referente más cercano en términos de integración con el LMS: importa grupos directamente desde Brightspace vía LTI, que es exactamente lo que necesita el proyecto. Su limitación es que no tiene app móvil y que requiere licencia institucional. PeerEval Dúo replica el concepto de importación desde Brightspace (via API en lugar de LTI) y lo lleva al contexto de app nativa.

**Peerceptiv** valida el concepto de que la detección de evaluadores inconsistentes es un valor agregado real. Aunque PeerEval Dúo no implementa calibración ni detección de outliers en esta versión, la arquitectura de dos apps separadas facilita añadir esa funcionalidad en el futuro a la app del docente sin afectar la app del estudiante.

**Brecha cubierta:** ninguno de los tres tiene app móvil nativa. En el contexto universitario colombiano, donde el acceso principal es desde celular, una app Flutter nativa garantiza notificaciones push oportunas y una UX fluida que una web responsiva no puede igualar.

---

### 4.2 Tabla resumen de decisiones

| Decisión | Justificación |
|---|---|
| Dos apps separadas con dominio compartido | UX especializada por rol; seguridad por diseño (el estudiante no tiene acceso físico al código del docente) |
| Monorepo con package `peereval_core` | Evita duplicación de lógica de negocio; FeedbackFruits y Peerceptiv confirman que la lógica puede centralizarse |
| Grupos importados desde Brightspace | Alineado con FeedbackFruits; elimina reingreso manual de datos ya existentes en el LMS |
| Verificación de rol al login en cada app | Si un docente usa la app de estudiante (o viceversa), recibe un error claro con indicación de la app correcta |
| Criterios fijos BARS × 4 sin configuración | Reduce carga de setup al docente y garantiza comparabilidad |
| Notificaciones push vía FCM | Los tres referentes solo usan correo; esto no es suficiente para ventanas de evaluación cortas |
| Sin autoevaluación | Enunciado explícito; simplifica el formulario del estudiante |
| Visibilidad pública/privada por evaluación | Necesidad confirmada en los tres referentes |

---
## 5. Capturas de UI — PeerEval
### 5.1 UI Profesor
| Pantalla | Captura |
|---|:---:|
| **Login** — (Roble) | ![Login](captures\Login.png) | 
| **Dashboard**  | ![Registro](captures\Dashboard.png) |
| **Grupos**  | ![Grupos](captures\Grupos.png) |
| **Evaluación**  | ![Evaluación](captures\Evaluación.png) | 
| **Resultados**  | ![Resultados](captures\Resultados.png) |
| **Resultados - Detalle**  | ![Resultados-Detalle](captures\Resultados-Detalle.png) |

### 5.2 UI Estudiante
| Pantalla | Captura |
|---|:---:|
| **Login** — (Roble) | ![Login](captures\Login_estudiante.png) | 
| **Cursos**  | ![Cursos](captures\Cursos.png) |
| **Evaluar**  | ![Evaluar](captures\Evaluar.png) |
| **Criterios**  | ![Criterios](captures\Criterios.png) | 
| **Resultados**  | ![Resultados](captures\Resultados_estudiante.png) |


*Propuesta elaborada por Flavio Arregoces — Febrero 2026*