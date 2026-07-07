import { create } from "zustand"
import { persist } from "zustand/middleware"
import type { Employee } from "@/types"
import api from "@/lib/api"
import Cookies from "js-cookie"

interface AuthState {
  user: Employee | null
  token: string | null
  isAuthenticated: boolean
  isLoading: boolean
  error: string | null
  login: (employeeId: string, password: string) => Promise<boolean>
  logout: () => Promise<void>
  loadUser: () => Promise<void>
  updateProfile: (data: { full_name?: string; position?: string; email?: string; password?: string }) => Promise<boolean>
  updateProfilePhoto: (file: File) => Promise<boolean>
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
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
            Cookies.set("ZNCQP_token", data.token, { expires: 7, sameSite: "strict" })
            set({
              user: data.user,
              token: data.token,
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
        Cookies.remove("ZNCQP_token")
        set({ user: null, token: null, isAuthenticated: false, isLoading: false })
      },

      loadUser: async () => {
        if (!get().token) {
          set({ isLoading: false })
          return
        }
        try {
          const res = await api.get("/auth/profile")
          set({ user: res.data.data, isAuthenticated: true, isLoading: false })
        } catch (_) {
          Cookies.remove("ZNCQP_token")
          set({ user: null, token: null, isAuthenticated: false, isLoading: false })
        }
      },

      updateProfile: async (data) => {
        try {
          const res = await api.put("/auth/profile", data)
          set({ user: { ...get().user, ...res.data.data } })
          return true
        } catch (err: any) {
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
        } catch (err: any) {
          return false
        }
      },
    }),
    {
      name: "ZNCQP-auth",
      partialize: (state) => ({ token: state.token }),
    }
  )
)
