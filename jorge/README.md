# PeerUn — Propuesta Funcional y Técnica (Jorge)

> **Estudiante:** Jorge Sanchez  
> **Proyecto:** Plataforma móvil de evaluación entre compañeros para trabajo colaborativo universitario  
> **Fecha:** 25 de febrero de 2026  
> **Tecnologías objetivo:** Flutter · GetX · Clean Architecture · Roble (Auth/DB) · n8n · Brightspace  

---

## Tabla de Contenidos

1. [Descripción de la propuesta](#1-descripción-de-la-propuesta)
2. [Objetivo del sistema](#2-objetivo-del-sistema)
3. [Alcance y supuestos](#3-alcance-y-supuestos)
4. [Experiencia de usuario (UX)](#4-experiencia-de-usuario-ux)
5. [Funcionalidades principales](#5-funcionalidades-principales)
6. [Flujo de evaluación](#6-flujo-de-evaluación)
7. [Arquitectura del sistema](#7-arquitectura-del-sistema)
8. [Integración con n8n y Brightspace](#8-integración-con-n8n-y-brightspace)
9. [Decisiones de diseño](#9-decisiones-de-diseño)
10. [Modelo de datos mínimo](#10-modelo-de-datos-mínimo)
11. [KPIs y métricas de éxito](#11-kpis-y-métricas-de-éxito)
12. [Limitaciones y evolución](#12-limitaciones-y-evolución)
13. [Referencias visuales (Capturas Jorge)](#13-referencias-visuales-capturas-jorge)

---

## 1. Descripción de la propuesta

La propuesta define una plataforma centrada en el **estudiante**, orientada a facilitar la evaluación entre compañeros dentro de cursos universitarios con trabajo en equipo. El sistema prioriza tres principios:

- **Claridad:** el usuario entiende rápidamente qué evaluar, cómo hacerlo y por qué es importante.
- **Rapidez:** el flujo minimiza fricción mediante scroll guiado, foco visual en la pregunta activa y acciones rápidas.
- **Responsabilidad:** se conserva la opción de reportar señales críticas (0 y 1) sin romper el cálculo de nota válida.

La experiencia está compuesta por pestañas y vistas clave: **Welcome**, **Cursos**, **Vista de Curso (calificaciones públicas/privadas)**, **Flujo de Evaluación**, **Perfil dinámico**, y una sección de **recursos formativos** para mejorar el trabajo en equipo.

---

## 2. Objetivo del sistema

Construir una solución móvil que permita evaluar desempeño colaborativo entre pares de forma estructurada, transparente y accionable, alineada con la operación académica existente en Brightspace.

### Objetivos específicos

1. Incrementar la participación estudiantil en procesos de evaluación entre pares.
2. Mostrar resultados útiles (promedio ponderado y detalle por compañero) con reglas de visibilidad pública o privada.
3. Reducir carga operativa docente mediante automatización de sincronización y disparo de evaluaciones vía n8n.
4. Reforzar competencias blandas mediante contenido de apoyo en la sección de recursos.

---

## 3. Alcance y supuestos

### En alcance

- App de estudiante con navegación por pestañas.
- Consulta de cursos del semestre.
- Evaluación por compañeros con escala académica y señales de alerta.
- Visualización de resultados por materia con promedio ponderado.
- Perfil con retroalimentación visual adaptada al rendimiento.
- Integración operativa con Brightspace a través de automatizaciones.

### Fuera de alcance

- **No se implementa interfaz administrativa para docentes** en esta versión.
- No se desarrolla módulo de creación manual de grupos dentro de la app.

### Supuestos operativos

- Brightspace es la fuente de verdad para cursos, categorías y composición de grupos.
- n8n orquesta sincronizaciones, activaciones y cierre de evaluaciones.
- Roble provee autenticación y persistencia de resultados.

---

## 4. Experiencia de usuario (UX)

La UX está diseñada para sostener participación, foco y percepción de justicia del proceso.

### 4.1 Pestaña Welcome

- Pantalla inicial motivacional para incentivar la calificación.
- Mensaje claro sobre el propósito: mejorar colaboración y visibilizar aportes reales.
- Llamado a la acción directo para comenzar o continuar evaluaciones pendientes.

### 4.2 Pestaña de Cursos

- Lista de cursos activos del semestre donde el usuario está inscrito.
- Estado de cada curso: evaluaciones activas, cerradas o pendientes.
- Sección inferior de **Recursos para ser mejor compañero** (lecturas, juegos, material didáctico interactivo).

### 4.3 Vista de Curso

- Encabezado fijo con **promedio ponderado acumulado** de la materia.
- Módulo de calificaciones con distinción entre:
  - **Públicas:** muestran valor numérico junto al nombre del compañero y estado de visibilidad.
  - **Privadas:** visibles solo bajo política interna de publicación (sin exposición grupal).

### 4.4 Perfil del usuario

- Fondo e imagen dinámica según promedio general.
- Mensajería personalizada (ejemplo: “Eres muy valorado, Jorge Sanchez”).
- Feedback visual correctivo cuando el promedio es bajo, orientado a mejora y no a castigo.

---

## 5. Funcionalidades principales

1. **Autenticación y sesión** de estudiante.
2. **Consulta de cursos** y acceso al detalle por materia.
3. **Motor de evaluación entre pares** sin autoevaluación.
4. **Escala extendida con señales 0/1**:
	- 2 a 5: rango válido de calificación académica.
	- 0 y 1: señal o denuncia; no ingresan al cálculo de nota válida.
5. **Botón rápido “Fue un excelente compañero”** que asigna 5 a todas las preguntas del compañero actual.
6. **Resultados con promedio ponderado** por materia y por estudiante evaluado.
7. **Recursos de aprendizaje colaborativo** integrados en la app.

---

## 6. Flujo de evaluación

El flujo busca reducir fatiga y sesgo de atención durante la calificación.

1. El estudiante entra al curso y selecciona una evaluación activa.
2. Se presenta el primer compañero elegible (sin autoevaluación).
3. Las preguntas se muestran con **opacidad reducida**, excepto la pregunta central activa.
4. Al responder, el sistema hace **scroll automático** hacia la siguiente pregunta.
5. El usuario puede:
	- Asignar valores de 2 a 5 para nota válida.
	- Usar 0 o 1 para reportar señal/denuncia.
	- Activar “Fue un excelente compañero” para completar con 5 de forma masiva.
6. Al finalizar cada compañero, se confirma el bloque y se continúa con el siguiente.
7. Al terminar todos los compañeros, se envía la evaluación y se registra trazabilidad de entrega.

### Regla de cálculo

- El promedio ponderado del curso considera únicamente calificaciones válidas (2–5).
- Valores 0 y 1 se registran como eventos de señalamiento para análisis institucional/seguimiento.

---

## 7. Arquitectura del sistema

Se adopta una arquitectura limpia para separar UI, dominio y datos.

```text
┌──────────────────────────────────────────────────────────────┐
│                    Aplicación Flutter                        │
│  (Welcome, Cursos, Curso, Evaluación, Perfil, Recursos)      │
├──────────────────────────────────────────────────────────────┤
│ Presentación (GetX)                                           │
│ Controllers · Estado reactivo · Rutas · Componentes de UI     │
├──────────────────────────────────────────────────────────────┤
│ Dominio                                                       │
│ Casos de uso: iniciar evaluación, calificar, calcular promedios│
│ Reglas: visibilidad pública/privada, exclusión 0/1 de notas   │
├──────────────────────────────────────────────────────────────┤
│ Datos                                                         │
│ Repositorios · Mappers · Fuentes remotas/locales              │
├──────────────────────────────────────────────────────────────┤
│ Infraestructura externa                                       │
│ Roble (Auth + DB) · Brightspace (LMS) · n8n (automatización)  │
└──────────────────────────────────────────────────────────────┘
```

### Componentes lógicos

- `AuthModule`: login y sesión.
- `CourseModule`: listado y detalle de cursos.
- `EvaluationModule`: cuestionario, validaciones y envío.
- `ResultsModule`: promedio ponderado y vista pública/privada.
- `ProfileModule`: visuales dinámicas por rendimiento.
- `ResourcesModule`: contenido para fortalecer trabajo en equipo.

---

## 8. Integración con n8n y Brightspace

### 8.1 Rol de Brightspace

- Fuente oficial de cursos, grupos y membresías.
- Punto de referencia para ventanas académicas y estructura de actividades.

### 8.2 Rol de n8n

n8n actúa como capa de orquestación sin exponer complejidad al usuario final:

1. **Sincronización programada** de cursos y grupos desde Brightspace hacia Roble.
2. **Disparo de evaluaciones** según fechas/eventos del LMS.
3. **Cierre automático** de ventanas de evaluación.
4. **Publicación de visibilidad** (pública/privada) según configuración.
5. **Notificaciones** de apertura/cierre y recordatorios.

### 8.3 Beneficios de esta decisión

- Menor carga manual operativa.
- Menor riesgo de desalineación entre app y LMS.
- Escalabilidad para múltiples cursos y cohortes sin crear panel admin dedicado.

---

## 9. Decisiones de diseño

1. **Enfoque mobile-first**: uso prioritario en contexto estudiantil móvil.
2. **Una sola experiencia de estudiante** en esta fase: evita complejidad prematura.
3. **Foco visual por opacidad**: aumenta precisión de respuesta pregunta a pregunta.
4. **Atajo de excelencia**: acelera escenarios de evaluación homogénea positiva.
5. **Perfil emocionalmente inteligente**: feedback visual para reforzar motivación y mejora.
6. **Recursos integrados en cursos**: convierte la app en herramienta formativa, no solo calificadora.
7. **Sin app admin docente**: la operación docente se delega a automatizaciones n8n + Brightspace.

---

## 10. Modelo de datos mínimo

```text
Usuario
- id
- nombre
- email
- rol (student)
- promedioGeneral

Curso
- id
- nombre
- periodo
- promedioPonderado

Evaluacion
- id
- cursoId
- nombre
- visibilidad (publica|privada)
- fechaApertura
- fechaCierre
- estado

Respuesta
- id
- evaluacionId
- evaluadorId
- evaluadoId
- criterio
- valor (0..5)
- esSenal (true cuando valor 0 o 1)
```

---

## 11. KPIs y métricas de éxito

- **Tasa de participación:** porcentaje de estudiantes que completan evaluación dentro de ventana.
- **Tiempo promedio de finalización:** duración media por evaluación.
- **Cobertura de recursos:** porcentaje de usuarios que consumen contenido de la sección formativa.
- **Distribución de señales (0/1):** trazabilidad de alertas por curso/equipo.
- **Consistencia de evaluación:** variación de calificaciones entre miembros de un mismo grupo.

---

## 12. Limitaciones y evolución

### Limitaciones actuales

- Sin panel de administración docente en frontend.
- Dependencia de la calidad y frecuencia de sincronización LMS.
- Interpretación de señales 0/1 requiere protocolo institucional de seguimiento.

### Evolución sugerida

- Analítica avanzada de sesgo y outliers.
- Módulo de recomendaciones automáticas de mejora por criterio.
- Integración de microcontenidos adaptativos según desempeño del perfil.

---

## 13. Referencias visuales (Capturas Jorge)

Las siguientes pantallas soportan la propuesta funcional y visual definida:

| Pantalla | Captura |
|---|---|
| Inicio de sesión | ![Inicio de sesion](Capturas/Inicio%20de%20sesion.png) |
| Registro | ![Registro](Capturas/Registro.png) |
| Welcome / Inicio | ![Inicio](Capturas/Inicio.png) |
| Vista principal | ![Principal](Capturas/Principal.png) |
| Bienvenida motivacional | ![Bienvenida](Capturas/Bienvenida.png) |
| Cursos | ![Curso](Capturas/Curso.png) |
| Calificaciones del curso | ![Calificacion](Capturas/Calificacion.png) |
| Recursos / Blog | ![Blog](Capturas/Blog.png) |
| Perfil dinámico | ![Perfil](Capturas/Perfil.png) |

---

## Conclusión

La propuesta de Jorge define una experiencia de evaluación entre pares clara, enfocada en participación y mejora continua del trabajo colaborativo. El diseño funcional cubre el ciclo completo del estudiante (motivación → evaluación → resultado → reflexión), mientras que la arquitectura técnica y la integración con n8n + Brightspace eliminan la necesidad de un panel administrativo adicional en esta fase del proyecto.

