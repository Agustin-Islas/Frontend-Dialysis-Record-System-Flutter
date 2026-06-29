# Frontend - RenApp

Aplicacion Flutter para pacientes y doctores dentro del sistema RenApp.

## Mision del frontend

El frontend debe hacer que el registro diario de dialisis peritoneal sea rapido, claro y confiable para el paciente, y que el doctor pueda revisar informacion clinica sin pelearse con planillas dispersas. La interfaz prioriza tareas reales: cargar cambios, revisar historial, asociar pacientes, generar reportes y detectar patrones.

## Estado actual

Implementado:

- App Flutter con soporte Web, Android, Windows, Linux, macOS e iOS generado por Flutter.
- Login con JWT.
- Registro de pacientes.
- Registro de doctores.
- Persistencia de access token y refresh token.
- Refresh automatico ante respuestas `401` en endpoints protegidos.
- `SessionGate` para redirigir por rol.
- Home de paciente:
  - pantalla de hoy;
  - carga de cambios;
  - edicion/eliminacion de cambios;
  - resumen diario;
  - navegacion por dias.
- Historial de paciente:
  - filtro por mes;
  - agrupacion por dia;
  - resumen mensual;
  - ultrafiltrados por semana;
  - exportacion PDF.
- Perfil de paciente:
  - edicion de datos personales;
  - concentraciones personalizadas;
  - cierre de sesion.
- Home de doctor:
  - pacientes asociados;
  - selector para agregar pacientes existentes;
  - busqueda por nombre, DNI o email;
  - desasociacion de pacientes;
  - detalle mensual del paciente;
  - exportacion PDF del paciente.
- Layout responsive para mobile y pantallas grandes.

## Tecnologias

- Flutter.
- Dart.
- Material UI.
- Dio.
- Flutter Secure Storage.
- universal_html para storage web.
- intl.
- pdf.
- share_plus.
- flutter_lints.

## Estructura

```text
lib/
+-- app.dart
+-- main.dart
+-- core/
|   +-- auth/
|   +-- config/
|   +-- di/
|   +-- network/
+-- features/
    +-- auth/
    +-- doctors/
    +-- patients/
    +-- reports/
    +-- sessions/
```

## Configuracion de API

El frontend usa `API_BASE_URL`.

Valor por defecto:

```text
http://localhost:8080
```

Ejemplo:

```powershell
flutter run -d web-server --dart-define=API_BASE_URL=http://localhost:8080
```

## Ejecucion local

Instalar dependencias:

```powershell
flutter pub get
```

Ejecutar en web server:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 3001
```

Analizar:

```powershell
dart analyze
```

Build web:

```powershell
flutter build web
```

## Flujo de autenticacion

1. Login envia email/password a `/auth/login`.
2. Backend responde access token y refresh token.
3. Frontend guarda tokens.
4. Frontend decodifica `role` del JWT.
5. Segun rol consulta:
   - `GET /api/doctors/me`
   - `GET /api/patients/me`
6. `SessionGate` abre la home correspondiente.
7. Interceptor agrega `Authorization: Bearer <token>` a requests protegidos.
8. Si un endpoint protegido responde `401`, intenta refresh con `/auth/refresh`.

Nota: si el login obtiene tokens pero falla la carga de `/me`, se limpian los tokens para evitar sesiones intermedias rotas.

## Pantallas actuales

### Auth

- `LoginScreen`
- `PatientRegisterScreen`
- `DoctorRegisterScreen`
- `SessionGate`

### Paciente

- `PatientHomeScreen`
- `PatientTodayScreen`
- `PatientHistoryScreen`
- `PatientProfileScreen`
- `SessionCreateBottomSheet`

### Doctor

- `DoctorHomeScreen`
- `DoctorPatientsScreen`
- `PatientDetailForDoctorScreen`

## Funcionalidades clinicas actuales

- Carga de cambio con:
  - fecha;
  - hora;
  - bolsa;
  - concentracion;
  - infusion;
  - drenaje;
  - observaciones.
- Concentraciones fijas y personalizadas.
- Resumen diario:
  - cantidad de sesiones;
  - infusion total;
  - drenaje total;
  - balance total.
- Resumen mensual:
  - total de cambios;
  - ultrafiltrados semanales;
  - historial agrupado por dia.
- PDF mensual.

## UX actual

- Navegacion inferior para paciente.
- Navegacion inferior para doctor.
- Cards y listas centradas con ancho maximo en web/desktop.
- Encabezados de historial reorganizados para mobile.
- Selector de pacientes para doctor con busqueda.
- Botones principales con iconos.
- Estados de carga, error y vacio en pantallas criticas.

## Riesgos y mejoras recomendadas

Prioridad alta:

- Web guarda tokens en `localStorage`; evaluar cookies HttpOnly/SameSite o endurecer proteccion XSS.
- No hay tests de widgets ni integracion de flujos criticos.
- El doctor puede seleccionar cualquier paciente expuesto por backend; conviene agregar consentimiento/invitacion.
- Validar convencion visual de UF/balance contra definicion clinica final.

Prioridad media:

- Agregar graficos reales para doctor y paciente.
- Agregar buscador/filtros avanzados en historial.
- Agregar cache/offline para carga diaria si no hay conexion.
- Mejorar manejo de errores por campo en formularios.
- Agregar i18n formal en vez de textos hardcodeados.
- Agregar estados skeleton o shimmer para cargas largas.

Prioridad baja:

- Unificar vocabulario UI: cambio, sesion, bolsa, UF, balance.
- Agregar tema visual mas consistente.
- Mejorar accesibilidad: contraste, tamanos, labels semanticos.

## Funcionalidades sugeridas

### Para pacientes

- Recordatorios de cambios por horario.
- Alerta si el paciente no cargo registros del dia.
- Registro de sintomas.
- Registro de peso, presion arterial, temperatura y glucemia.
- Resumen semanal facil de entender.
- Historial de observaciones.
- Modo offline con sincronizacion posterior.

### Para doctores

- Dashboard con pacientes priorizados.
- Grafico de UF diaria/semanal/mensual.
- Grafico infusion vs drenaje.
- Calendario de adherencia por paciente.
- Alertas por registros faltantes.
- Alertas por valores fuera de rango.
- Notas clinicas privadas por paciente.
- Exportacion mas completa con firma/datos del doctor.
- Filtros: sin registros hoy, UF baja, observaciones recientes, pacientes nuevos.

### Notificaciones

- Notificaciones locales para paciente.
- Push notifications cuando haya backend listo.
- Resumen diario al doctor.
- Alertas configurables por paciente.
- Mensajes o avisos simples doctor-paciente.

## Verificacion reciente

- `dart analyze`: sin issues.
- `flutter build web`: compilo correctamente.
- Flutter informo advertencias de compatibilidad Wasm por dependencias web, no errores de build.

## Notas de deploy

- `CODEMAGIC_DEPLOY.md` y `RENDER_WEB_DEPLOY.md` contienen notas especificas de deploy.
- `Dockerfile` y `render-nginx.conf.template` estan disponibles para despliegue web.
- Para web productivo, definir `API_BASE_URL` al construir.

## Roadmap frontend

1. Estabilizacion:
   - tests;
   - errores por campo;
   - accesibilidad;
   - revisar almacenamiento de tokens web.
2. Dashboard clinico:
   - KPIs de doctor;
   - graficos;
   - filtros;
   - alertas basicas.
3. Notificaciones:
   - recordatorios locales;
   - alertas de registros faltantes;
   - push notifications.
4. Experiencia avanzada:
   - offline;
   - sintomas/signos vitales;
   - reportes longitudinales;
   - configuracion por paciente.
