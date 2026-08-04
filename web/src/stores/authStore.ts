import { create } from "zustand"
import type { Employee } from "@/types"
import api, { setAccessToken, getAccessToken, setOnAuthFailure, getErrorMessage } from "@/lib/api"
import { rehydrateTheme } from "@/stores/themeStore"

interface AuthState {
  user: Employee | null
  isAuthenticated: boolean
  isLoading: boolean
  error: string | null
  login: (employeeId: string, password: string) => Promise<boolean>
  logout: () => Promise<void>
  loadUser: () => Promise<void>
  updateProfile: (data: { full_name?: string; position?: string; email?: string; password?: string }) => Promise<boolean>
  updateProfilePhoto: (file: File) => Promise<boolean>
}

export const useAuthStore = create<AuthState>()((set, get) => ({
  user: null,
  isAuthenticated: false,
  isLoading: true,
  error: null,

  login: async (employeeId, password) => {
    set({ isLoading: true, error: null })
    try {
      const res = await api.post("/auth/login", {
        employee_id: employeeId,
        password,
      })
      const data = res.data
      if (data.success) {
        setAccessToken(data.token)
        set({
          user: data.user,
          isAuthenticated: true,
          isLoading: false,
        })
        rehydrateTheme(data.user?.employee_id)
        return true
      }
      set({ error: data.message, isLoading: false })
      return false
    } catch (err) {
      set({ error: getErrorMessage(err, "Login failed"), isLoading: false })
      return false
    }
  },

  logout: async () => {
    try {
      await api.post("/auth/logout")
    } catch {
      // session already gone — still clear local state
    }
    setAccessToken(null)
    set({ user: null, isAuthenticated: false, isLoading: false })
    rehydrateTheme(null)
  },

  loadUser: async () => {
    const existingToken = getAccessToken()

    if (!existingToken) {
      try {
        const refreshRes = await api.post("/auth/refresh")
        const newToken = refreshRes.data?.token
        if (newToken) {
          setAccessToken(newToken)
        } else {
          set({ isLoading: false })
          return
        }
      } catch {
        set({ isLoading: false })
        return
      }
    }

    try {
      const res = await api.get("/auth/profile")
      set({ user: res.data.data, isAuthenticated: true, isLoading: false })
      rehydrateTheme(res.data.data?.employee_id)
    } catch {
      setAccessToken(null)
      set({ user: null, isAuthenticated: false, isLoading: false })
    }
  },

  updateProfile: async (data) => {
    try {
      const res = await api.put("/auth/profile", data)
      set({ user: { ...get().user, ...res.data.data } })
      return true
    } catch {
      return false
    }
  },

  updateProfilePhoto: async (file) => {
    try {
      const formData = new FormData()
      formData.append("photo", file)
      const res = await api.post("/auth/profile/photo", formData, {
        headers: { "Content-Type": "multipart/form-data" },
      })
      set({ user: { ...get().user, ...res.data.data } })
      return true
    } catch {
      return false
    }
  },
}))

setOnAuthFailure(() => {
  useAuthStore.setState({ user: null, isAuthenticated: false, isLoading: false })
})
