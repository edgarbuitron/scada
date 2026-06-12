# Add Sensors Panel and Symmetrize Neumatico Dashboard

The goal is to add a Sensors panel to the Neumatico station in `scada_neumatico.dart`, placing it to the left of the Actuators panel with both having the same height and symmetric styling.

## Proposed Changes

### [Neumatico Component]

#### [scada_neumatico.dart](file:///C:/Users/cesar/StudioProjects/scada/lib/scada_neumatico.dart)

- **Layout Update**:
    - Modify the main `Column` to include a new row at the bottom containing both the Sensors and Actuators panels.
    - Use `SizedBox(height: 350, ...)` or a similar fixed height to ensure both panels are equal.
- **Sensors Panel**:
    - Implement `_buildSensorsPanel()` method.
    - Implement `_sensorRow()` to match the visual style and size of actuator rows (larger padding, explicit text colors).
- **Actuators Panel**:
    - Revert the Actuators panel from a 2-column grid back to a single column list (or adjust as needed) to match the vertical Sensors panel layout.
- **Symmetry**:
    - Ensure item sizes (sensor rows and actuator rows) have consistent padding and heights.

## Verification Plan

### Automated Tests
- Run `flutter analyze lib/scada_neumatico.dart`.

### Manual Verification
- Open the "Centro Neumático" screen.
- Verify that:
    1. The 2D Diagram is at the top.
    2. The Audit Panel is in the middle (full width).
    3. The bottom contains a Sensors panel (left) and an Actuators panel (right) of the same height.
    4. Buttons in both panels look uniform in size.
