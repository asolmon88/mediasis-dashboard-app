// Spanish is the source language. Only app-owned copy is passed here.
String translateAppString(String source, String language) {
  if (language != 'en') return source;
  final direct = englishStrings[source];
  if (direct != null) return direct;
  if (source.startsWith('Tiempo real desconectado:')) {
    return source.replaceFirst(
      'Tiempo real desconectado:',
      'Live connection lost:',
    );
  }
  if (source.startsWith('La prueba se imprimio correctamente en ')) {
    return source.replaceFirst(
      'La prueba se imprimio correctamente en ',
      'Test printed successfully on ',
    );
  }
  if (source.startsWith('No se pudo conectar con ')) {
    return source.replaceFirst(
      'No se pudo conectar con ',
      'Could not connect to ',
    );
  }
  if (source.startsWith('Configura los tiempos para ')) {
    return source.replaceFirst(
      'Configura los tiempos para ',
      'Configure times for ',
    );
  }
  return source;
}

const englishStrings = <String, String>{
  'Idioma': 'Language',
  'Sistema': 'System',
  'Idioma de la aplicación': 'App language',
  'Elige cómo se muestran los textos de esta tablet.':
      'Choose how text is shown on this tablet.',
  'Usar idioma del dispositivo': 'Use device language',
  'El idioma no cambia la moneda ni el idioma del recibo del negocio.':
      'Language does not change the business currency or receipt language.',
  'Cancelar': 'Cancel',
  'Guardar': 'Save',
  'Confirmar': 'Confirm',
  'Eliminar': 'Delete',
  'Editar': 'Edit',
  'Agregar': 'Add',
  'Cerrar': 'Close',
  'Abrir': 'Open',
  'Cerrar sesión': 'Sign out',
  'Cerrar sesion': 'Sign out',
  'Ingresar': 'Sign in',
  'Correo electrónico': 'Email',
  'Contraseña': 'Password',
  'Tu contraseña': 'Your password',
  'correo@empresa.com': 'email@business.com',
  'Selecciona un local': 'Select a location',
  'Actualmente estás en': "You're currently in",
  'Buscar local…': 'Search locations…',
  'Elige el local con el que trabajaras en esta tablet.':
      'Choose the location you will use on this device.',
  'Reintentar': 'Retry',
  'Refrescar': 'Refresh',
  'Actualizar': 'Refresh',
  'Cambiar': 'Change',
  'Tiempo real': 'Live orders',
  'Órdenes': 'Orders',
  'Ordenes': 'Orders',
  'Pedidos': 'Orders',
  'Productos': 'Products',
  'Configuración': 'Settings',
  'Configuracion': 'Settings',
  'Orden': 'Order',
  'Cliente': 'Customer',
  'Total': 'Total',
  'Recibo': 'Receipt',
  'Estado': 'Status',
  'Pago': 'Payment',
  'Creada': 'Created',
  'Fecha': 'Date',
  'Ver recibo': 'View receipt',
  'Rastreo': 'Tracking',
  'Ver detalles': 'View details',
  'Recoger ahora': 'Pick up now',
  '¿Solicitar recogida ahora?': 'Request pickup now?',
  'Marcar lista': 'Mark ready',
  'Marcar lista para recoger': 'Mark ready for pickup',
  'Marcar en camino': 'Mark on the way',
  'Marcar entregada': 'Mark delivered',
  'Marcar preparando': 'Mark preparing',
  'Pendiente': 'Pending',
  'Nueva': 'New',
  'Nuevas': 'New',
  'Prep.': 'Prep.',
  'Prep../Cancelados': 'Prep../Cancelled',
  'Listas': 'Ready',
  'Listas para recoger': 'Ready for pickup',
  'Lista para recoger': 'Ready for pickup',
  'Entregadas': 'Delivered',
  'Recoger/Entrega': 'Pickup/Delivery',
  'Listas/En camino': 'Ready/On the way',
  'Preparar': 'Prepare',
  'sin seleccionar': 'not selected',
  'Preparando': 'Preparing',
  'Atrasado': 'Overdue',
  'Listo': 'Ready',
  'Listo para recoger': 'Ready for pickup',
  'Lista': 'Ready',
  'Aceptada': 'Accepted',
  'Entregada': 'Delivered',
  'Cancelada': 'Canceled',
  'Pagada': 'Paid',
  'Rechazada': 'Declined',
  'Visible': 'Visible',
  'Oculto': 'Hidden',
  'Ordenar': 'Sort',
  'Mas recientes': 'Newest first',
  'Mas antiguas': 'Oldest first',
  'Mayor total': 'Highest total',
  'Menor total': 'Lowest total',
  'Anterior': 'Previous',
  'Siguiente': 'Next',
  'Buscar por orden o cliente': 'Search by order or customer',
  'Ubicación': 'Location',
  'Minutos': 'Minutes',
  'Opciones de impresora': 'Printer options',
  'Buscar producto': 'Search products',
  'Nombre': 'Name',
  'Precio': 'Price',
  'Visibilidad': 'Visibility',
  'Opciones': 'Options',
  'Variantes': 'Variants',
  'Sin opciones': 'No options',
  'Sin variantes': 'No variants',
  'No se pudieron cargar los productos': 'Could not load products',
  'No se pudieron cargar las órdenes': 'Could not load orders',
  'No se pudieron cargar los locales o su configuracion regional. Intenta de nuevo.':
      'Could not load locations or their market settings. Please retry.',
  'No se pudo cargar la configuracion regional del local. Intenta de nuevo.':
      'Could not load this location’s market settings. Please retry.',
  'No hay locales disponibles para esta cuenta.':
      'No locations are available for this account.',
  'No se pudieron cargar los locales. Intenta de nuevo.':
      'Could not load locations. Please retry.',
  'Tu sesión ha expirado. Inicia sesión nuevamente.':
      'Your session expired. Please sign in again.',
  'Ahora no': 'Not now',
  'Activar': 'Enable',
  'Notificaciones': 'Notifications',
  'Activar notificaciones': 'Enable notifications',
  'Abrir ajustes': 'Open settings',
  'Abrir configuracion': 'Open settings',
  'Permiso concedido': 'Permission granted',
  'Permiso denegado': 'Permission denied',
  'Sin permiso': 'No permission',
  'Impresoras': 'Printers',
  'Gestionar': 'Manage',
  'Buscar': 'Discover',
  'Escanear red': 'Scan network',
  'Buscar SUNMI': 'Find SUNMI',
  'Agregar IP': 'Add IP',
  'Encontradas': 'Discovered',
  'Configuradas': 'Configured',
  'Impresiones fallidas': 'Failed print jobs',
  'Buscando impresoras disponibles...': 'Finding available printers...',
  'Eliminar impresora': 'Delete printer',
  'Imprimir prueba': 'Print test',
  'Impresion automatica': 'Automatic printing',
  'Impresión automática': 'Automatic printing',
  'Opciones avanzadas': 'Advanced options',
  'Formato de recibo': 'Receipt format',
  'Diseno visual': 'Visual design',
  'Diseño visual': 'Visual design',
  'Texto rapido': 'Fast text',
  'Texto rápido': 'Fast text',
  'Direccion IP o hostname': 'IP address or hostname',
  'Puerto': 'Port',
  'Cortar papel al terminar': 'Cut paper after printing',
  'Revisa el nombre, la direccion y el puerto.':
      'Check the name, address, and port.',
  'Imprimir ahora': 'Print now',
  'Abrir recibo en el navegador': 'Open receipt in browser',
  'Recibo de la orden': 'Order receipt',
  'No hay impresoras': 'No printers',
  'Configurar impresora': 'Set up printer',
  'Imprimir en todas': 'Print on all printers',
  'No se pudo abrir el recibo.': 'Could not open the receipt.',
  'Enviando recibo a la impresora...': 'Sending receipt to printer...',
  'Tiempo de preparación': 'Preparation time',
  'Tiempo de preparacion': 'Preparation time',
  'Métodos de entrega por ubicación': 'Delivery methods by location',
  'Configura el tiempo estimado de preparación para cada servicio del local activo.':
      'Set the estimated preparation time for each service at the active location.',
  'Métodos de entrega': 'Delivery methods',
  'Tiempo hasta que el pedido esté listo': 'Time until the order is ready',
  'No hay métodos de delivery': 'No delivery methods',
  'No se pudieron cargar los métodos de delivery':
      'Could not load delivery methods',
  'Cerrar app': 'Close ordering',
  'Abrir app': 'Open ordering',
  'Lista en': 'Ready in',
  'minutos': 'minutes',
  'activos': 'active',
  'abiertos': 'open',
  'minuto': 'minute',
  'Tiempo estimado para tener el pedido listo.': 'Estimated preparation time.',
  'Horario de preparación informado por Uber.':
      'Preparation time provided by Uber.',
  'Un socio de la app recolectara el pedido cuando este listo.':
      'A delivery partner will collect the order when it is ready.',
  'Método de delivery': 'Delivery method',
  'Método de pago': 'Payment method',
  'Descuento': 'Discount',
  'Detalle del descuento': 'Discount details',
  'Detalles adicionales': 'Additional details',
  'Detalle de Uber': 'Uber details',
  'Sin datos': 'No data',
  'Sin resultados': 'No results',
  'No hay pedidos': 'No orders',
  'Cargando pedidos...': 'Loading orders...',
  'Cargando...': 'Loading...',
  'Version actual': 'Current version',
  'Version requerida': 'Required version',
  'Version publicada': 'Published version',
  'MARKET_SETTINGS_MISSING':
      'Business market settings are missing. Contact your administrator.',
  'MARKET_SETTINGS_UNAVAILABLE':
      'Market settings are unavailable. Please retry.',
  'MARKET_SETTINGS_INVALID': 'Business market settings are invalid.',
  'UNAUTHORIZED': 'Your session is no longer authorized. Please sign in again.',
  'Inicia sesión': 'Sign in',
  'Accede a tu panel de mediasis Orders.':
      'Access your Mediasis Orders dashboard.',
  'Actualizacion requerida': 'Update required',
  'Necesitas instalar una nueva version de Mediasis Orders para continuar usando la app en Windows.':
      'Install a new Mediasis Orders version to continue using the app on Windows.',
  'Administrar': 'Manage',
  'Gestión': 'Management',
  'Ocultar': 'Hide',
  'Producto': 'Product',
  'Catálogo actual': 'Current catalog',
  'Revisa el catálogo y oculta productos cuando sea necesario.':
      'Review the catalog and hide products when needed.',
  'Este producto no tiene variantes u opciones configuradas.':
      'This product has no variants or options configured.',
  'Sin elecciones configuradas.': 'No choices configured.',
  'Pedidos en tiempo real': 'Live orders',
  'No hay pedidos activos': 'No active orders',
  'No hay pedidos en esta columna.': 'No orders in this column.',
  'Cargando pedidos en tiempo real...': 'Loading live orders...',
  'No se pudieron cargar los pedidos': 'Could not load orders',
  'Sin rastreo': 'No tracking',
  'Sin opciones adicionales.': 'No additional options.',
  'Ver imagen': 'View image',
  'No se pudo abrir la imagen.': 'Could not open the image.',
  'Selecciona una impresora': 'Select a printer',
  'Configura una impresora IP para imprimir este recibo.':
      'Set up an IP printer to print this receipt.',
  'Elige como quieres ver o imprimir este recibo.':
      'Choose how you want to view or print this receipt.',
  'Recibos directos a tu red': 'Receipts sent directly to your network',
  'Conecta impresoras ESC/POS por IP. La configuracion se guarda por local en este dispositivo.':
      'Connect ESC/POS printers over IP. Settings are stored per location on this device.',
  'Busca una impresora o agrega su direccion IP.':
      'Find a printer or add its IP address.',
  'Usa el area imprimible estandar de 512 puntos para evitar cortes laterales.':
      'Uses the standard 512-dot printable area to avoid side clipping.',
  '0.0.0.0 no es una direccion valida para conectarse. Usa la direccion IPv4 de la impresora, por ejemplo 192.168.x.x.':
      '0.0.0.0 is not a valid destination. Use the printer IPv4 address, for example 192.168.x.x.',
  'Impresoras de recibos': 'Receipt printers',
  'Notificaciones de pedidos': 'Order notifications',
  'No se pudo sincronizar. Intenta nuevamente.':
      'Could not synchronize. Please retry.',
  'No tienes acceso al local de esta notificación.':
      'You cannot access the location in this notification.',
  'Activa las alertas de pedidos': 'Enable order alerts',
  'Te avisaremos cuando llegue un pedido nuevo, incluso si la app está en segundo plano.':
      'We will notify you when a new order arrives, even while the app is in the background.',
  'Uber intentara enviar al repartidor lo antes posible y entregar el pedido cuanto antes. La disponibilidad y el tiempo de llegada dependen de Uber, y puede que el horario no se pueda modificar otra vez.':
      'Uber will try to send a courier and deliver the order as soon as possible. Availability and arrival time depend on Uber, and the schedule may not be editable again.',
  'Uber': 'Uber',
  'Error de integración con Uber': 'Uber integration error',
  'Courier en camino': 'Courier on the way',
  'Tiempos': 'Times',
  'A más tardar': 'Latest',
  'Uber llega aproximadamente': 'Uber arrives around',
  'Puede recoger desde': 'Pickup available from',
  'Llegada estimada': 'Estimated arrival',
  'Direcciones': 'Addresses',
  'Comprobante': 'Proof',
  'Firma': 'Signature',
  'Motivo de cancelación': 'Cancellation reason',
  'No entregado': 'Not delivered',
  'Hora en que estará listo el pedido': 'Time when the order will be ready',
  'Tiempo de preparación de delivery': 'Delivery preparation time',
  'Delivery por ubicación': 'Delivery by location',
  'Gestiona el tiempo de preparación': 'Manage preparation time',
  'Edita el tiempo estimado de cada método de delivery para la ubicación activa.':
      'Edit the estimated time for each delivery method at the active location.',
  'Selecciona una ubicación activa para editar tiempo de preparación por local.':
      'Select an active location to edit its preparation time.',
  'Tiempo de preparación para pickup_ready_dt':
      'Preparation time for pickup readiness',
  'Maneja la app': 'Manage ordering',
  'Personaliza esta tablet y administra las herramientas del local.':
      'Personalize this tablet and manage the location tools.',
  'La app está abierta': 'Ordering is open',
  'La app está cerrada': 'Ordering is closed',
  'Selecciona un local para cambiar este estado.':
      'Select a location to change this status.',
  'Este local': 'This location',
  'el local activo': 'the active location',
  'puede recibir pedidos nuevos.': 'can receive new orders.',
  'no recibirá pedidos nuevos.': 'will not receive new orders.',
  'Confirmas que quieres cerrar la app y dejar de recibir pedidos nuevos?':
      'Do you want to close ordering and stop receiving new orders?',
  'Confirmas que quieres abrir la app y volver a recibir pedidos nuevos?':
      'Do you want to open ordering and receive new orders again?',
  'No hay impresoras configuradas.': 'No printers are configured.',
  'Agrega una impresora para configurarla y probarla.':
      'Add a printer to configure and test it.',
  'Todavia no hay impresoras para este local.':
      'There are no printers for this location yet.',
  'trabajo(s) requieren atencion.': 'print job(s) need attention.',
  'configurada(s),': 'configured,',
  'automática(s).': 'automatic.',
  'Activas para los pedidos nuevos.': 'Active for new orders.',
  'Bloqueadas en los ajustes del dispositivo.': 'Blocked in device settings.',
  'Pendientes de sincronización.': 'Waiting to synchronize.',
  'Actívalas para no perder pedidos.': 'Enable them so you do not miss orders.',
  'Selecciona un local para administrarlo.': 'Select a location to manage it.',
  'Cuando existan métodos de delivery configurados, aparecerán aquí.':
      'Configured delivery methods will appear here.',
  'Notificaciones no disponibles': 'Notifications unavailable',
  'Este dispositivo no admite notificaciones.':
      'This device does not support notifications.',
  'Comprobando notificaciones': 'Checking notifications',
  'Comprobando el estado de las notificaciones...':
      'Checking notification status...',
  'Notificaciones activas': 'Notifications active',
  'Este dispositivo recibirá alertas para los pedidos nuevos del local activo.':
      'This device will receive alerts for new orders at the active location.',
  'Notificaciones bloqueadas': 'Notifications blocked',
  'Actívalas desde los ajustes del dispositivo para recibir pedidos en segundo plano.':
      'Enable them in device settings to receive orders in the background.',
  'Sincronización pendiente': 'Synchronization pending',
  'El permiso está activo. Sincroniza este dispositivo para recibir pedidos.':
      'Permission is active. Synchronize this device to receive orders.',
  'Activa las notificaciones': 'Enable notifications',
  'Recibirás alertas de pedidos nuevos aunque la app esté en segundo plano.':
      'You will receive new-order alerts even while the app is in the background.',
  'El diseno visual reproduce el recibo del sitio web.':
      'The visual design reproduces the website receipt.',
  'No hay una ubicación activa.': 'There is no active location.',
  'No hay una ubicación activa para actualizar este estado.':
      'There is no active location for this update.',
  'No hay una ubicación activa para actualizar este producto.':
      'There is no active location for this product update.',
  'No hay una ubicación activa para cargar el detalle.':
      'There is no active location for loading these details.',
  'No hay una ubicacion activa para actualizar el pedido.':
      'There is no active location for updating this order.',
  'No se pudo actualizar el estado de la orden.':
      'Could not update the order status.',
  'No se pudo actualizar el estado del pedido.':
      'Could not update the order status.',
  'No se pudo actualizar el pedido.': 'Could not update the order.',
  'No se pudo cargar el pedido nuevo.': 'Could not load the new order.',
  'No se pudo abrir el pedido para esta ubicación.':
      'Could not open the order for this location.',
  'No se pudo abrir el detalle del pedido.':
      'Could not open the order details.',
  'No se pudo cargar el detalle del pedido.':
      'Could not load the order details.',
  'No se pudo actualizar un pedido en tiempo real.':
      'Could not update a live order.',
  'Para ver esta orden pasala a preparando.':
      'Move this order to Preparing to view it.',
  'La solicitud ya esta en proceso.': 'This request is already in progress.',
  'Primero debes imprimir una prueba correctamente.':
      'Print a successful test before enabling this option.',
  'Recibo reimpreso correctamente.': 'Receipt reprinted successfully.',
  'No se pudo cargar el recibo para impresion automatica.':
      'Could not load the receipt for automatic printing.',
  'Tiempo de preparación actualizado.': 'Preparation time updated.',
  'Datos inválidos para actualizar el tiempo de preparación.':
      'Invalid preparation-time data.',
  'No hay una sesion activa para actualizar la hora de pickup.':
      'There is no active session for updating the pickup time.',
  'No hay una sesion activa para llamar a Uber.':
      'There is no active session for calling Uber.',
  'No hay una sesion activa para actualizar la entrega.':
      'There is no active session for updating the delivery.',
  'No hay una sesion activa para actualizar la eleccion.':
      'There is no active session for updating the choice.',
  'El servidor no devolvio una respuesta valida.':
      'The server returned an invalid response.',
  'No se pudo conectar con el servidor. Revisa la conexion.':
      'Could not connect to the server. Check the connection.',
  'No se pudo solicitar la recogida ahora.': 'Could not request pickup now.',
  'No se pudo abrir el enlace de rastreo.': 'Could not open the tracking link.',
  'Unexpected error while signing in.':
      'An unexpected error occurred while signing in.',
  'Unexpected error while signing out.':
      'An unexpected error occurred while signing out.',
  'Impresora principal': 'Main printer',
  'Agregar impresora': 'Add printer',
  'Editar impresora': 'Edit printer',
  'Detalle del pedido': 'Order details',
  'Total productos': 'Products total',
  'Cantidad': 'Quantity',
  'No especificado': 'Not specified',
  'ACTIVO': 'ACTIVE',
  'INACTIVO': 'INACTIVE',
  'Cancelado': 'Canceled',
  'Cancelados': 'Canceled',
  'Recogiendo': 'Picking up',
  'Recogido': 'Picked up',
  'En camino': 'On the way',
  'Devuelto': 'Returned',
  'ETA recogida': 'Pickup ETA',
  'Recogida lista': 'Pickup ready',
  'Límite recogida': 'Pickup deadline',
  'Recogida completada': 'Pickup completed',
  'ETA entrega': 'Delivery ETA',
  'Límite entrega': 'Delivery deadline',
  'Entregado': 'Delivered',
  'Recogida': 'Pickup',
  'Entrega': 'Delivery',
  'Acción': 'Action',
  'Re-solicitar Uber': 'Request Uber again',
  'Llamar Uber': 'Request Uber',
  'Solicitando...': 'Requesting...',
  'El delivery anterior falló o fue cancelado.':
      'The previous delivery failed or was canceled.',
  'Sin delivery asignado.': 'No delivery is assigned.',
  'Configura el tiempo estimado por método para ':
      'Configure the estimated time by method for ',
  'la ubicación activa': 'the active location',
  'Selecciona una ubicación activa para editar los tiempos de preparación.':
      'Select an active location to edit preparation times.',
};
