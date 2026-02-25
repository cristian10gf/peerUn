# 📱 Evalia -- Propuesta de solución
| **Estudiante** | Sandro Torres |
|---------------|------------------|
| **Proyecto**  | Aplicación móvil de evaluación entre pares |
| **Fecha**     | 25 de febrero de 2026 |

---

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

### 1️⃣ Peergrade

#### Descripción

Peergrade es una plataforma especializada en evaluación entre pares en contextos educativos formales. Permite a los estudiantes evaluar el trabajo de sus compañeros mediante rúbricas estructuradas definidas por el docente. El sistema asigna evaluadores automáticamente y gestiona la entrega, revisión y publicación de resultados dentro de un flujo claramente definido.

Está orientada principalmente a educación superior y se integra con diversos LMS mediante estándar LTI.

#### Aportes relevantes al proyecto

- Evaluación estructurada basada en criterios.
- Asignación automática de evaluaciones.
- Configuración de anonimato entre evaluadores.
- Promedios automáticos por criterio.
- Integración con LMS institucionales.

#### Limitaciones 

- Interfaz más optimizada para escritorio que para móvil.
- Flujo de evaluación con múltiples pasos que puede resultar extenso.
- Visualización de resultados poco simplificada.
- Modelo de licencia institucional paga.

#### Incidencia en Evalia

Evalia adopta la estructura formal de rúbricas y la asignación automática de evaluaciones, pero propone una experiencia mobile-first simplificada, concentrando la evaluación en una sola vista clara y reduciendo fricción en el proceso.

---

### 2️⃣ FeedbackFruits (Peer Review Module)

#### Descripción

FeedbackFruits es una plataforma de aprendizaje colaborativo que incluye un módulo especializado en evaluación entre pares. Está diseñada para integrarse profundamente con LMS institucionales y ofrece herramientas avanzadas de seguimiento de participación, calidad del feedback y métricas de interacción.

Su enfoque es robusto y analíticamente detallado, orientado a instituciones que buscan trazabilidad avanzada en procesos evaluativos.

#### Aportes relevantes al proyecto

- Métricas detalladas de participación.
- Seguimiento de calidad del feedback.
- Comparación entre autoevaluación y evaluación de pares.
- Integración fuerte con LMS como Brightspace.
- Paneles analíticos para docentes.

#### Limitaciones 

- Complejidad alta en configuración.
- Interfaz visualmente densa.
- Sobrecarga de métricas que puede dificultar interpretación rápida.
- Solución completamente institucional y de alto costo.

#### Incidencia en Evalia

Evalia retoma la idea de incorporar métricas comparativas y visualización de resultados, pero propone un enfoque minimalista, priorizando indicadores claros y comprensibles en pantalla móvil, evitando la saturación informativa.

---

### 3️⃣ Eduflow

#### Descripción

Eduflow es una plataforma digital orientada al aprendizaje activo que integra evaluación entre pares dentro de flujos de trabajo estructurados. Permite la creación de actividades colaborativas donde los estudiantes entregan trabajos, evalúan a otros participantes y reciben retroalimentación de manera organizada y progresiva.

Se caracteriza por una interfaz moderna y una experiencia de usuario más visual y simplificada en comparación con otras plataformas tradicionales.

#### Aportes relevantes al proyecto

- Flujo progresivo claro (entrega → evaluación → resultados).
- Interfaz limpia y visualmente ordenada.
- Integración con LMS mediante LTI.
- Gestión estructurada de rúbricas.
- Experiencia más intuitiva para estudiantes.

#### Limitaciones 

- Orientación más amplia hacia aprendizaje activo general, no exclusivamente peer assessment.
- Enfoque principalmente web.
- Licencia institucional paga.
- Métricas colaborativas menos profundas que otras soluciones más técnicas.

#### Incidencia en Evalia

Evalia adopta de Eduflow el enfoque visual minimalista y el flujo progresivo claramente segmentado, pero lo adapta específicamente al contexto de evaluación entre pares universitaria, optimizando la experiencia para dispositivos móviles y simplificando aún más la interacción.

---

### 🧩 Análisis Comparativo y Posicionamiento

El análisis de los referentes demuestra que las soluciones actuales priorizan robustez institucional, integración con LMS y modelos evaluativos estructurados. Sin embargo, presentan en común una experiencia poco optimizada para entornos móviles y una tendencia hacia interfaces densas y complejas.

Evalia se posiciona como una propuesta que:

- Mantiene la estructura formal de rúbricas.
- Integra métricas comparativas relevantes.
- Reduce complejidad visual y operativa.
- Prioriza experiencia móvil minimalista.
- Se orienta específicamente al contexto universitario con integración a Brightspace.

De esta manera, la propuesta no compite en robustez institucional avanzada, sino en claridad, accesibilidad y experiencia de usuario.

---

## Arquitectura

## 🏗️ Composición y Diseño de la Solución

### Enfoque Arquitectónico General

Evalia se diseña bajo **Clean Architecture**, separando claramente responsabilidades en distintas capas, garantizando independencia de la interfaz de usuario, independencia del framework, independencia de la base de datos, alta testabilidad y escalabilidad futura.

La aplicación se concibe como una solución *mobile-first*, estructurada en arquitectura cliente-servidor, con integración a Brightspace como LMS para la obtencion de los grupos correspondientes a cada curso, de los cuales los profesores podrán crear evaluaciones para los estudiantes.

---

## 🧱 Arquitectura en Capas (Clean Architecture)

La aplicación se divide en cuatro capas principales:

### 1️⃣ Capa de Presentación (Presentation Layer)

Responsable de la interfaz móvil.

- Pantallas (Cursos, Actividades, Evaluación, Resultados).
- Gestión de estado.
- Navegación.
- Validaciones básicas de entrada.

Esta capa no contiene lógica de negocio, únicamente se comunica con los casos de uso.

---

### 2️⃣ Capa de Aplicación (Use Cases / Application Layer)

Contiene la lógica de negocio específica del sistema:

- Crear actividad de evaluación.
- Asignar evaluadores automáticamente.
- Calcular promedios por criterio.
- Calcular métricas colaborativas.
- Determinar visibilidad de resultados.

Los casos de uso son independientes del framework móvil y de la base de datos.

---

### 3️⃣ Capa de Dominio (Domain Layer)

Núcleo del sistema.

Incluye:

- Entidades principales (Usuario, Curso, grupo, Rúbrica, Evaluación).
- Reglas de negocio puras.
- Modelos independientes de infraestructura.
- Interfaces de repositorios.

Esta capa no depende de ninguna otra.

---

### 4️⃣ Capa de Infraestructura (Infrastructure Layer)

Encargada de:

- Implementación de repositorios.
- Conexión a base de datos.
- Integración con Brightspace (API o LTI, no sé cuál sea el medio por el que se puede hacer esto con BS, así que ambas opciones estan especificadas, una cosa que es posible justamente gracias a clean arch ya que se podrían incluso hacer ambas implementaciones sin afectar la lógica de negocio).
- Autenticación institucional.
- Servicios externos.

Aquí se implementan los detalles técnicos sin afectar la lógica central.

---

## 👥 Gestión de Roles

Se propone una única aplicación con diferenciación por rol (Docente / Estudiante).

La separación se realiza mediante:

- Control de acceso basado en rol.
- Autorización gestionada desde el backend (nutriendose de las capacidades de la plataforma "roble").
- Interfaces dinámicas según permisos.

Esta decisión reduce mantenimiento y asegura coherencia visual.

---

## 🗄️ Modelo de Datos Conceptual

Entidades principales:

- Usuario
- Curso
- Grupo
- Actividad
- Rúbrica
- Criterio
- Evaluación
- Resultado

Las relaciones siguen principios de bajo acoplamiento y alta cohesión.

---

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


