import { create } from "zustand"
import type { Employee } from "@/types"
import api, { setAccessToken, getAccessToken, setOnAuthFailure } from "@/lib/api"

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
        return true
      }
      set({ error: data.message, isLoading: false })
      return false
    } catch (err: any) {
      const msg = err.response?.data?.message || "Login failed"
      set({ error: msg, isLoading: false })
      return false
    }
  },

  logout: async () => {
    try {
      await api.post("/auth/logout")
    } catch (_) {}
    setAccessToken(null)
    set({ user: null, isAuthenticated: false, isLoading: false })
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
