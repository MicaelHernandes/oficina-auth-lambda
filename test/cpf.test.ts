import { describe, it, expect } from "vitest";
import { isValidCpf, normalizeCpf } from "../src/lib/cpf";

describe("normalizeCpf", () => {
  it("remove máscara", () => {
    expect(normalizeCpf("529.982.247-25")).toBe("52998224725");
  });
  it("lida com entrada vazia", () => {
    expect(normalizeCpf("")).toBe("");
  });
});

describe("isValidCpf", () => {
  it("aceita CPF válido com máscara", () => {
    expect(isValidCpf("529.982.247-25")).toBe(true);
  });
  it("aceita CPF válido sem máscara", () => {
    expect(isValidCpf("52998224725")).toBe(true);
  });
  it("rejeita dígitos verificadores errados", () => {
    expect(isValidCpf("529.982.247-24")).toBe(false);
  });
  it("rejeita sequência repetida", () => {
    expect(isValidCpf("111.111.111-11")).toBe(false);
  });
  it("rejeita comprimento inválido", () => {
    expect(isValidCpf("123")).toBe(false);
  });
  it("rejeita não numérico", () => {
    expect(isValidCpf("abc.def.ghi-jk")).toBe(false);
  });
});
