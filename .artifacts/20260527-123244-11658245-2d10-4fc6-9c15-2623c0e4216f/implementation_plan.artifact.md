# Exportación de Datos a Excel en Analytics

Añadir un botón verde "Excel" a la izquierda del botón de Reporte para exportar los KPIs actuales de la planta a un archivo `.xlsx`.

## User Review Required

> [!NOTE]
> Se utilizará la librería `syncfusion_flutter_xlsio` para generar el archivo Excel, ya que es compatible con el resto de la suite de Syncfusion usada en el proyecto y evita conflictos con `lottie`.

## Proposed Changes

### Componente de Analíticas

#### [analitycs.dart](file:///C:/Users/cesar/StudioProjects/scada/lib/analitycs.dart)

- Implementar el método `_exportToExcel` que:
    1. Crea un `Workbook`.
    2. Llena una `Worksheet` con los encabezados: Maqueta, Producción, Tiempo Activo, Fallas y Consumo.
    3. Agrega los datos actuales del `UsageMonitor`.
    4. Guarda el archivo en la carpeta de documentos del dispositivo.
- Añadir un nuevo `ElevatedButton.icon` de color verde en la cabecera del dashboard.

```dart
// Lógica principal de exportación
Future<void> _exportToExcel(StationAnalyticsData data) async {
  final xlsio.Workbook workbook = xlsio.Workbook();
  final xlsio.Worksheet sheet = workbook.worksheets[0];

  sheet.getRangeByIndex(1, 1).setText('REPORTE INDUSTRIAL - SCADA MASTER');
  sheet.getRangeByIndex(3, 1).setText('Maqueta:');
  sheet.getRangeByIndex(3, 2).setText(data.name);
  // ... más campos ...

  final List<int> bytes = workbook.saveAsStream();
  workbook.dispose();

  // Guardado en archivo
  final String path = (await getApplicationDocumentsDirectory()).path;
  final String fileName = '$path/Reporte_${data.name}.xlsx';
  final File file = File(fileName);
  await file.writeAsBytes(bytes, flush: true);
}
```

## Verification Plan

### Manual Verification
- Ejecutar la aplicación en modo debug.
- Navegar al panel de Analíticas.
- Presionar el botón verde "Excel".
- Verificar que aparezca un mensaje de éxito o que el archivo se genere en la ruta especificada.
