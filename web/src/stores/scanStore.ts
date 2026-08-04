import { create } from "zustand"
import api from "@/lib/api"
import type { ScanLog } from "@/types"

export interface ScanResultData {
  type: "OUT" | "IN"
  employee_name: string
  employee_id: string
  start_time: string
  end_time: string
  new_status: string
}

interface ScanState {
  isLoading: boolean
  error: string | null
  lastResult: { success: boolean; data?: ScanResultData; message?: string } | null
  history: ScanLog[]
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
    } catch (err) {
      const msg =
        (err as { response?: { data?: { message?: string } } }).response?.data?.message ||
        (err as { message?: string }).message ||
        "Could not validate QR code"
      set({ error: msg, lastResult: { success: false, message: msg }, isLoading: false })
      return false
    }
  },

  loadHistory: async () => {
    set({ historyLoading: true })
    try {
      const res = await api.get("/scan/history")
      set({ history: res.data.data, historyLoading: false })
    } catch {
      set({ historyLoading: false })
    }
  },

  clearResult: () => set({ lastResult: null, error: null }),
}))
