// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Aucorsa GO!';

  @override
  String get settings => 'Ajustes';

  @override
  String get info => 'Información';

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get appearanceSubtitle => 'Elige entre luz y oscuridad';

  @override
  String get ratingTitle => '¿Disfrutando de la app?';

  @override
  String get ratingSubtitle => 'Deja tu reseña en la tienda';

  @override
  String get freeSoftwareTitle => 'Esto es software libre';

  @override
  String get freeSoftwareSubtitle => 'Código fuente disponible para todos';

  @override
  String get authorTitle => 'Creado por Chechu R.';

  @override
  String get authorSubtitle => 'Aplicaciones libres bien diseñadas';

  @override
  String get emailTitle => 'Envíame un correo';

  @override
  String get emailSubtitle => 'Reporta fallos o solicita funciones';

  @override
  String get dataOriginTitle => 'No afiliado con AUCORSA';

  @override
  String get dataOriginSubtitle =>
      'Esta aplicación no está afiliada ni es la aplicación oficial desarrollada por AUCORSA. Toda la información relacionada con las líneas de autobuses, los recorridos, las paradas y los tiempos de paso es proporcionada por AUCORSA, la empresa responsable del transporte público urbano.\n\nEl objetivo principal de esta aplicación es facilitar el acceso a la información pública de manera más intuitiva y accesible para los usuarios, mejorando así la experiencia de quienes utilizan los servicios de transporte público. Buscamos contribuir al fomento de una movilidad sostenible y eficiente al brindar herramientas que promuevan el uso del transporte colectivo como una alternativa cómoda y responsable para la movilidad urbana.\n\nEsta iniciativa independiente se compromete a ofrecer datos precisos y actualizados, aunque es importante tener en cuenta que la fuente original de toda la información es AUCORSA. Recomendamos siempre contrastar los datos con los canales oficiales para garantizar la máxima precisión.';

  @override
  String get licenseTitle => 'Licencias de software libre';

  @override
  String versionTitle(String version, String buildNumber) {
    return 'Versión $version ($buildNumber)';
  }

  @override
  String busLine(String lineNumber) {
    return 'Línea $lineNumber';
  }

  @override
  String get busLines => 'Líneas';

  @override
  String get busStopTileFavorite => 'Favorito';

  @override
  String get busStopTileNoEstimations => 'No hay estimaciones disponibles';

  @override
  String get busStopTileNow => 'Ahora';

  @override
  String get systemTheme => 'Tema del sistema';

  @override
  String get lightTheme => 'Tema claro';

  @override
  String get darkTheme => 'Tema oscuro';

  @override
  String get favoritesPageTitle => 'Favoritos';

  @override
  String get noFavoritesTitle => 'No hay favoritos';

  @override
  String get noFavoritesSubtitle => 'Pulsa aquí para ver todas las paradas';

  @override
  String get stops => 'Paradas';

  @override
  String get allStops => 'Todas las paradas';

  @override
  String get feriaEventDescription => 'Servicios especiales de AUCORSA';

  @override
  String get events => 'Eventos';

  @override
  String get feriaDialogBody =>
      'Aprovecha las líneas de autobuses especiales que te llevarán a la Feria de Córdoba';

  @override
  String get deleteStopTitle => 'Quitar parada';

  @override
  String get deleteStopSubtitle =>
      '¿Estás seguro de que quieres quitar esta parada de tus favoritos?';

  @override
  String get deleteStopCta => 'Quitar';

  @override
  String get locationPermissionTitle => 'Permiso de ubicación';

  @override
  String get locationPermissionDescription =>
      'El acceso a la ubicación está permanentemente denegado. Por favor, abre los ajustes y habilítalo manualmente.';

  @override
  String get locationOutsideMapTitle => 'Ubicación fuera del área del mapa';

  @override
  String get locationOutsideMapDescription =>
      'Tu ubicación actual está fuera del área cubierta por este mapa sin conexión.';

  @override
  String get mapLoadError => 'No se ha podido cargar el mapa sin conexión.';

  @override
  String get retry => 'Volver a intentar';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get editStopTitle => 'Editar nombre';

  @override
  String get deleteBonobusDialogTitle => 'Eliminar bonobús';

  @override
  String get deleteBonobusDialogSubtitle =>
      '¿Estás seguro de que quieres eliminar los detalles del bonobús?';

  @override
  String get bonobus => 'Bonobús';

  @override
  String get aucorsa => 'Aucorsa';

  @override
  String get consorcio => 'Consorcio de Transporte Metropolitano';

  @override
  String lastUpdated(String time) {
    return 'Última actualización $time';
  }

  @override
  String get scanBonobusTitle => 'Escanea tu bonobús';

  @override
  String get scanBonobusSubtitle => 'Usa tu dispositivo para leer tu saldo';

  @override
  String get topUpBonobusTitle => 'Recargar bonobús';

  @override
  String get topUpBonobusSubtitle => 'Descubre más sobre cómo hacerlo aquí';

  @override
  String get editBonobusTitle => 'Editar número de tarjeta';

  @override
  String get deleteBonobusTitle => 'Eliminar detalles';

  @override
  String get deleteBonobusSubtitle => 'Esto lo eliminará de la aplicación';

  @override
  String get addBonobusTitle => 'Añadir tu bonobús';

  @override
  String get addBonobusSubtitle =>
      'Selecciona tu proveedor de bonobús antes de añadir los datos de tu tarjeta';

  @override
  String get scanBonobusPageTitle => 'Escanea tu bonobús';

  @override
  String get scanBonobusPageSubtitle =>
      'Acerca tu tarjeta bonobús a la parte trasera de tu dispositivo para escanearla';

  @override
  String get aucorsaUseAccount => 'Iniciar sesión o crear cuenta';

  @override
  String get aucorsaAccountTitle => 'Conecta tu cuenta';

  @override
  String get aucorsaMovementsAccountSubtitle =>
      'Inicia sesión con tu cuenta de AUCORSA para consultar el historial de movimientos. Esta tarjeta debe estar ya vinculada a esa cuenta. Esta aplicación nunca lee ni guarda tu contraseña.';

  @override
  String get aucorsaMovementsHelpTitle => 'Ayuda';

  @override
  String get aucorsaMovementsHelpIntro =>
      'AUCORSA solo devuelve los movimientos de una tarjeta a una cuenta de usuario que la tenga añadida, y además exige que la cuenta y el bonobús compartan el mismo DNI o NIF. Por eso hace falta crear una cuenta: la aplicación inicia sesión en aucorsa.es por ti y pide los movimientos de la tarjeta con esa sesión. Sin una cuenta que cumpla ambas condiciones AUCORSA no devuelve nada, por mucho que escanees la tarjeta.';

  @override
  String get aucorsaMovementsHelpStepsTitle => 'Lo que tienes que hacer';

  @override
  String get aucorsaMovementsHelpStepAccountTitle =>
      'Crea una cuenta en AUCORSA';

  @override
  String get aucorsaMovementsHelpStepAccountSubtitle =>
      'Crea la cuenta en aucorsa.es. AUCORSA te pedirá tu nombre, un correo electrónico, una contraseña y un DNI o NIF, que tiene que ser el mismo con el que está registrado el bonobús. Si ya tienes cuenta, pasa directamente al paso 4.';

  @override
  String get aucorsaMovementsHelpStepActivateTitle =>
      'Activa la cuenta desde tu correo';

  @override
  String get aucorsaMovementsHelpStepActivateSubtitle =>
      'AUCORSA envía un correo de confirmación justo después del registro. La cuenta sigue inactiva hasta que abras el enlace de ese correo, y hasta entonces el inicio de sesión siempre falla. Revisa la carpeta de spam si no te llega.';

  @override
  String get aucorsaMovementsHelpStepCardTitle =>
      'Añade esta tarjeta a tu cuenta';

  @override
  String get aucorsaMovementsHelpStepCardSubtitle =>
      'Dentro de tu cuenta, abre la sección Mis tarjetas de aucorsa.es y registra el número impreso en el bonobús. Solo las tarjetas vinculadas a la cuenta con la que inicias sesión muestran sus movimientos.';

  @override
  String get aucorsaMovementsHelpStepSignInTitle =>
      'Inicia sesión en la aplicación';

  @override
  String get aucorsaMovementsHelpStepSignInSubtitle =>
      'Inicia sesión con esa misma cuenta. La sesión se queda en este dispositivo, así que solo tendrás que repetirlo si AUCORSA la cierra.';

  @override
  String get aucorsaMovementsHelpStepRefreshTitle => 'Actualiza el historial';

  @override
  String get aucorsaMovementsHelpStepRefreshSubtitle =>
      'Desliza hacia abajo en la lista de movimientos para volver a pedírselos a AUCORSA. Un viaje o una recarga pueden tardar unos minutos en aparecer.';

  @override
  String get aucorsaCardNumber => 'Número de tarjeta';

  @override
  String get aucorsaCardMovements => 'Historial de movimientos';

  @override
  String get aucorsaCardMovementsSubtitle => 'Consulta los últimos movimientos';

  @override
  String get aucorsaMovementOnlineTopUp => 'Recarga online';

  @override
  String get aucorsaMovementOnlineTopUpPending => 'Recarga online pendiente';

  @override
  String get aucorsaMovementBusJourney => 'Viaje';

  @override
  String get aucorsaMovementTransfer => 'Transbordo';

  @override
  String get aucorsaDataError => 'No se han podido cargar los datos de AUCORSA';

  @override
  String get aucorsaMovementsUnavailableTitle =>
      'Historial de movimientos no disponible';

  @override
  String get aucorsaMovementsUnavailableSubtitle =>
      'No hemos podido cargar los movimientos de este bonobús. Consulta el botón de ayuda de arriba e inténtalo de nuevo.';

  @override
  String get aucorsaNoMovementsTitle => 'No hay movimientos';

  @override
  String get aucorsaNoMovementsSubtitle =>
      'AUCORSA no ha devuelto movimientos para este bonobús. Consulta el botón de ayuda de arriba para comprobar que la tarjeta está vinculada a tu cuenta.';
}
