// Validação de CPF (dígitos verificadores) e normalização.

/** Remove tudo que não for dígito. */
export function normalizeCpf(input: string): string {
  return (input ?? "").replace(/\D/g, "");
}

/**
 * Valida um CPF pelos dígitos verificadores.
 * Aceita com ou sem máscara; rejeita sequências repetidas (ex.: 111.111.111-11).
 */
export function isValidCpf(input: string): boolean {
  const cpf = normalizeCpf(input);

  if (cpf.length !== 11) return false;
  if (/^(\d)\1{10}$/.test(cpf)) return false; // todos os dígitos iguais

  const digits = cpf.split("").map(Number);

  const checkDigit = (length: number): number => {
    let sum = 0;
    for (let i = 0; i < length; i++) {
      sum += digits[i] * (length + 1 - i);
    }
    const rest = (sum * 10) % 11;
    return rest === 10 ? 0 : rest;
  };

  return checkDigit(9) === digits[9] && checkDigit(10) === digits[10];
}
