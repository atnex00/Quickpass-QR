import '@testing-library/jest-dom'
import { vi } from 'vitest'

const storage: Record<string, string> = {}
const mockStorage: Storage = {
  getItem: vi.fn((key: string) => storage[key] ?? null),
  setItem: vi.fn((key: string, value: string) => { storage[key] = value }),
  removeItem: vi.fn((key: string) => { delete storage[key] }),
  clear: vi.fn(() => { for (const k in storage) delete storage[k] }),
  get length() { return Object.keys(storage).length },
  key: vi.fn((index: number) => Object.keys(storage)[index] ?? null),
}

Object.defineProperty(globalThis, 'localStorage', { value: mockStorage, writable: true })

Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
})