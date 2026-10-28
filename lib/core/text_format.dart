/// Upper-cases the first letter, e.g. `chest` -> `Chest`.
String capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
