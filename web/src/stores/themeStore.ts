import { create } from "zustand"
import { persist } from "zustand/middleware"

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
    { name: "quickpass-theme" }
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
