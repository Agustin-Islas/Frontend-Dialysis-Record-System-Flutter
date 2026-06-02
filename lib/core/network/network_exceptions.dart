class NetworkExceptions {
  static String getMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Credenciales inválidas o sesión expirada';
      case 500:
        return 'Error del servidor';
      default:
        return 'Error desconocido';
    }
  }
}
