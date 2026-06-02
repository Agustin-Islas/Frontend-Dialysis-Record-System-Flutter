# Dialysis Record – Frontend

## Descripción general

Este proyecto corresponde al **frontend** del sistema *Dialysis Record*, una aplicación cliente desarrollada en **Flutter** orientada a pacientes y profesionales de la salud.

La aplicación consume una **API REST segura**, permitiendo la autenticación mediante **JWT** y el acceso a funcionalidades personalizadas según el rol del usuario. Su objetivo principal es facilitar el registro y la visualización estructurada de sesiones de diálisis peritoneal, priorizando claridad, usabilidad y seguridad.

---

## Arquitectura y organización

El frontend está estructurado siguiendo una **arquitectura modular basada en features**, lo que facilita el mantenimiento, la escalabilidad y la extensión futura del sistema.

### Core

Contiene componentes transversales reutilizables en toda la aplicación:

- Cliente HTTP basado en **Dio**
- Manejo de tokens JWT
- Almacenamiento seguro de credenciales
- Interceptores de red
- Utilidades y constantes globales
- Manejo básico de errores

### Features

Cada funcionalidad principal se organiza como un módulo independiente:

#### Auth
- Pantallas de login y registro
- Control del estado de autenticación
- Integración con el flujo JWT del backend

#### Patient
- Visualización de información del paciente
- Acceso al historial de sesiones
- Navegación por fechas

#### Session
- Registro de sesiones de diálisis
- Listado cronológico de registros
- Comunicación directa con la API para envío y consulta de datos

Cada feature contiene:
- Screens (UI)
- Controllers / ViewModels
- Models (DTOs del frontend)
- Servicios de red específicos

---

## Seguridad y autenticación

La aplicación implementa un flujo de autenticación **stateless**, alineado con el backend:

- Login contra la API
- Recepción y almacenamiento seguro del access token
- Inclusión automática del JWT en cada request mediante interceptores
- Protección de pantallas según estado de autenticación
- Persistencia de sesión entre reinicios de la app

Este enfoque garantiza que solo usuarios autenticados puedan acceder a los recursos protegidos.

---

## Tecnologías utilizadas

- Flutter  
- Dart  
- Dio (HTTP client)  
- Flutter Secure Storage (mobile)  
- LocalStorage (web)  
- Material UI  
- Arquitectura basada en features  

---

## Funcionalidades principales

- Autenticación de usuarios mediante JWT
- Persistencia segura de sesión
- Consumo de API REST protegida
- Registro de sesiones de diálisis
- Visualización del historial clínico ordenado por fecha
- Navegación simple e intuitiva
- Separación clara entre UI y lógica de negocio
- Arquitectura modular orientada a la escalabilidad

---

## Estado del proyecto

Aplicación en **desarrollo activo**, con:

- Flujo de autenticación funcional
- Comunicación estable con el backend
- Base estructural sólida para extender funcionalidades

Preparada para evolucionar hacia una aplicación completa **multiplataforma (Android / Web)**.

---

## Objetivo final

El objetivo del frontend es brindar una interfaz clara, accesible y confiable para el seguimiento diario de la diálisis peritoneal, facilitando la carga de datos por parte del paciente y el análisis clínico por parte del profesional de la salud.

Esta implementación establece una base sólida para una aplicación médica real, segura y escalable, integrada con un backend robusto.
