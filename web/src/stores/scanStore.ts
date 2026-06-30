import { create } from "zustand"
import api from "@/lib/api"

interface ScanState {
  isLoading: boolean
  error: string | null
  lastResult: { success: boolean; data?: any; message?: string } | null
  history: any[]
  historyLoading: boolean
  validateScan: (qrData: string) => Promise<boolean>
  loadHistory: () => Promise<void>
  clearResult: () => void
}

export const useScanStore = create<ScanState>((set) => ({
  isLoading: false,
  error: null,
  lastResult: null,
  history: [],
  historyLoading: false,

  validateScan: async (qrData) => {
    set({ isLoading: true, error: null, lastResult: null })
    try {
      const res = await api.post("/scan/validate", { qr_data: qrData })
      set({ lastResult: res.data, isLoading: false })
      return true
    } catch (err: any) {
      const msg = err.response?.data?.message || "Could not validate QR code"
      set({ error: msg, lastResult: { success: false, message: msg }, isLoading: false })
      return false
    }
  },

  loadHistory: async () => {
    set({ historyLoading: true })
    try {
      const res = await api.get("/scan/history")
      set({ history: res.data.data, historyLoading: false })
    } catch (_) {
      set({ historyLoading: false })
    }
  },

  clearResult: () => set({ lastResult: null, error: null }),
}))
