import { MatchModel } from "src/core/models/core.MatchModel";

export function validateMatchMode(
    matchMode: MatchModel,
    fieldName: string
  ): void {
    if (!matchMode.matchMode) {
      if (matchMode.value != null && matchMode.value !== '') {
        throw new Error(`When match mode is empty for ${fieldName}, value must be empty, null or array.`);
      }
      return;
    }
  
    // Agrega aquí más validaciones según los casos que ya has definido.
  }