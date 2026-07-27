import { create } from "zustand"
import { persist, createJSONStorage, type StateStorage } from "zustand/middleware"
import { useAuthStore } from "@/stores/authStore"

type Theme = "light" | "dark" | "system"

interface ThemeState {
  theme: Theme
  setTheme: (theme: Theme) => void
  resolved: () => "light" | "dark"
}

function systemPrefersDark(): boolean {
  if (typeof window === "undefined") return false
  return window.matchMedia("(prefers-color-scheme: dark)").matches
}

function themeStorageKey(): string {
  const id = useAuthStore.getState().user?.employee_id
  return id ? `quickpass-theme-${id}` : "quickpass-theme"
}

const userScopedStorage: StateStorage = {
  getItem: (name) => localStorage.getItem(themeStorageKey()) ?? localStorage.getItem(name),
  setItem: (_name, value) => localStorage.setItem(themeStorageKey(), value),
  removeItem: (name) => {
    localStorage.removeItem(themeStorageKey())
    localStorage.removeItem(name)
  },
}

export const useThemeStore = create<ThemeState>()(
  persist(
    (set, get) => ({
      theme: "system",
      setTheme: (theme) => set({ theme }),
      resolved: () => {
        const t = get().theme
        if (t === "system") return systemPrefersDark() ? "dark" : "light"
        return t
      },
    }),
    {
      name: "quickpass-theme",
      storage: createJSONStorage(() => userScopedStorage),
    }
  )
)

export function applyTheme() {
  const resolved = useThemeStore.getState().resolved()
  const root = document.documentElement
  if (resolved === "dark") {
    root.classList.add("dark")
  } else {
    root.classList.remove("dark")
  }
}

export function rehydrateTheme() {
  useThemeStore.persist.rehydrate()
}
