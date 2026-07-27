import { useEffect, useSyncExternalStore } from "react"
import { useThemeStore, applyTheme } from "@/stores/themeStore"

export default function ThemeProvider({ children }: { children: React.ReactNode }) {
  const theme = useSyncExternalStore(
    (cb) => useThemeStore.subscribe(cb),
    () => useThemeStore.getState().theme
  )

  useEffect(() => {
    applyTheme()
    const mql = window.matchMedia("(prefers-color-scheme: dark)")
    const handler = () => {
      if (useThemeStore.getState().theme === "system") {
        applyTheme()
      }
    }
    mql.addEventListener("change", handler)
    return () => mql.removeEventListener("change", handler)
  }, [theme])

  return <>{children}</>
}
