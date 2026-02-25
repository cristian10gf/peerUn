# 📱 Evalia -- Propuesta de solución
| **Estudiante** | Sandro Torres |
|---------------|------------------|
| **Proyecto**  | Aplicación móvil de evaluación entre pares |
| **Fecha**     | 25 de febrero de 2026 |
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![GetX](https://img.shields.io/badge/GetX-8A2BE2?style=for-the-badge)
![Clean Architecture](https://img.shields.io/badge/Clean%20Architecture-4CAF50?style=for-the-badge)
![Roble](https://img.shields.io/badge/Roble-555555?style=for-the-badge)
![Auth](https://img.shields.io/badge/Auth-FF6F00?style=for-the-badge)
![Brightspace](https://img.shields.io/badge/Brightspace-FF6C00?style=for-the-badge)
![Integration](https://img.shields.io/badge/Integration-1976D2?style=for-the-badge)

## Introducción

Evalia es una aplicación móvil diseñada para facilitar y optimizar los procesos de evaluación entre pares en actividades colaborativas académicas. La plataforma permite a docentes activar evaluaciones estructuradas por criterios y a los estudiantes valorar el desempeño de sus compañeros de manera organizada, clara y objetiva.

La propuesta se enfoca en ofrecer una experiencia minimalista y fácil de usar, priorizando la claridad en la interacción y la visualización de resultados. A diferencia de los sistemas tradicionales integrados en plataformas LMS, Evalia busca mejorar la experiencia móvil mediante una interfaz simplificada y una estructura funcional centrada exclusivamente en el proceso de evaluación colaborativa.
---

## Referentes Analizados

### 1️⃣ Moodle

![Moodle](https://img.shields.io/badge/Moodle-LMS-orange?style=flat-square&logo=moodle&logoColor=white)

![Moodle Mobile](https://img.shields.io/badge/Enfoque-Rúbricas-blue?style=flat-square)
![Rol](https://img.shields.io/badge/Roles-Docente%20%2F%20Estudiante-green?style=flat-square)

<img src="https://upload.wikimedia.org/wikipedia/commons/6/6a/Moodle-logo.svg" width="200"/>

#### Descripción

Moodle es un sistema de gestión de aprendizaje (LMS) ampliamente utilizado en educación superior. Permite la creación de actividades evaluativas estructuradas mediante rúbricas y ofrece visualización de calificaciones tanto para docentes como para estudiantes.

#### Aportes relevantes al proyecto

- Implementación formal de rúbricas con criterios definidos.
- Configuración de evaluaciones con parámetros de visibilidad.
- Acceso diferenciado según rol (docente / estudiante).
- Gestión estructurada de cursos y actividades.

#### Limitaciones 

- Experiencia móvil poco optimizada.
- Interfaz densa y sobrecargada visualmente.
- Analítica limitada en términos de visualización clara y sintética.

#### Incidencia en esta propuesta

Evalia toma la estructura formal de criterios de Moodle, pero simplifica radicalmente la experiencia móvil, priorizando claridad, navegación reducida y visualización minimalista de métricas.

---

### 2️⃣ Peergrade

![Peergrade](https://img.shields.io/badge/Peergrade-Peer%20Assessment-purple?style=flat-square)

#### Descripción

Peergrade es una plataforma especializada en evaluación entre pares. Permite a los estudiantes evaluar trabajos de sus compañeros mediante rúbricas estructuradas y proporciona retroalimentación detallada.

#### Aportes relevantes al proyecto

- Evaluación estructurada entre pares.
- Exclusión de autoevaluación.
- Promedios por criterio.
- Resultados visibles según configuración del docente.

#### Limitaciones 

- Interfaz más orientada a escritorio que a experiencia móvil nativa.
- Visualización analítica poco simplificada.
- Flujo de evaluación con múltiples pasos que pueden generar fricción.

#### Incidencia en esta propuesta

Evalia adopta el enfoque específico de evaluación entre pares de Peergrade, pero lo rediseña bajo un principio de reducción cognitiva, concentrando la evaluación en una sola pantalla clara y directa.

---

### 3️⃣ Google Classroom

![Google Classroom](https://img.shields.io/badge/Google%20Classroom-Education-green?style=flat-square&logo=googleclassroom&logoColor=white)

#### Descripción

Google Classroom es una plataforma educativa ampliamente adoptada para la gestión de cursos, tareas y calificaciones en entornos académicos.

#### Aportes relevantes al proyecto

- Experiencia móvil limpia y estructurada por cursos.
- Navegación clara mediante tarjetas (cards).
- Diferenciación visual entre actividades activas y cerradas.
- Simplicidad en interacción docente-estudiante.

#### Limitaciones 

- No integra evaluación estructurada entre pares como núcleo funcional.
- Carece de métricas colaborativas comparativas.
- No ofrece analítica detallada por criterio.

#### Incidencia en esta propuesta

Evalia adopta la claridad visual y la navegación estructurada por cursos de Google Classroom, pero incorpora un módulo especializado de evaluación entre pares con métricas comparativas.

---

### 🧩 Conclusión Comparativa

En conjunto, los referentes analizados demuestran que si bien existen soluciones robustas para la gestión de cursos y evaluación académica, ninguna combina de manera optimizada la evaluación estructurada entre pares con una experiencia móvil minimalista y centrada exclusivamente en métricas colaborativas.

El objetivo de evalia es posicionarse como una propuesta que de la mejor manera posible integra las fortalezas de estas plataformas, reduciendo su complejidad y adaptando el proceso evaluativo a una experiencia móvil clara, directa y analíticamente sólida.

---

## Arquitectura

Texto...

---

## 🔄 Flujo Funcional

### 👨‍🏫 Profesor

1. Login
2. Crear evaluación
3. Ver resultados

### 👨‍🎓 Estudiante

1. Login
2. Evaluar
3. Ver resultados

