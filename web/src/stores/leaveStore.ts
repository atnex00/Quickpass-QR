import { create } from "zustand"
import type { LeaveRequest } from "@/types"
import api from "@/lib/api"

interface LeaveState {
  history: LeaveRequest[]
  historyTotal: number
  historyPage: number
  historyLimit: number
  historyPages: number
  activeLeave: LeaveRequest | null
  pendingRequests: LeaveRequest[]
  approvedLeaves: LeaveRequest[]
  isLoading: boolean
  error: string | null
  loadHistory: (status?: string, page?: number, limit?: number) => Promise<void>
  loadActiveLeave: () => Promise<void>
  submitLeave: (data: {
    leave_date: string
    start_time: string
    end_time: string
    reason: string
  }) => Promise<boolean>
  loadPendingRequests: () => Promise<void>
  approveLeave: (leaveId: string) => Promise<boolean>
  rejectLeave: (leaveId: string, reason: string) => Promise<boolean>
  loadApprovedLeaves: () => Promise<void>
  revokeApproval: (leaveId: string) => Promise<boolean>
}

export const useLeaveStore = create<LeaveState>((set) => ({
  history: [],
  historyTotal: 0,
  historyPage: 1,
  historyLimit: 10,
  historyPages: 1,
  activeLeave: null,
  pendingRequests: [],
  approvedLeaves: [],
  isLoading: false,
  error: null,

  loadHistory: async (status, page = 1, limit = 10) => {
    set({ isLoading: true, error: null })
    try {
      const params: any = { page, limit }
      if (status) params.status = status
      const res = await api.get("/leave/history", { params })
      const p = res.data.pagination || {}
      set({
        history: res.data.data,
        historyTotal: p.total || 0,
        historyPage: p.page || page,
        historyLimit: p.limit || limit,
        historyPages: p.pages || 1,
        isLoading: false,
      })
    } catch (err: any) {
      set({ error: err.response?.data?.message || "Could not load history — refresh the page", isLoading: false })
    }
  },

  loadActiveLeave: async () => {
    set({ isLoading: true })
    try {
      const res = await api.get("/leave/active")
      set({ activeLeave: res.data.data, isLoading: false })
    } catch (_) {
      set({ activeLeave: null, isLoading: false })
    }
  },

  submitLeave: async (data) => {
    set({ isLoading: true, error: null })
    try {
      const res = await api.post("/leave/request", data)
      const newLeave = res.data.data
      set((s) => ({ history: [newLeave, ...s.history], isLoading: false }))
      return true
    } catch (err: any) {
      set({ error: err.response?.data?.message || "Could not submit leave — check the form and try again", isLoading: false })
      return false
    }
  },

  loadPendingRequests: async () => {
    set({ isLoading: true, error: null })
    try {
      const res = await api.get("/supervisor/pending")
      set({ pendingRequests: res.data.data, isLoading: false })
    } catch (err: any) {
      set({ error: err.response?.data?.message || "Could not load pending requests", isLoading: false })
    }
  },

  approveLeave: async (leaveId) => {
    try {
      await api.post(`/supervisor/approve/${leaveId}`)
      set((s) => ({ pendingRequests: s.pendingRequests.filter((l) => l.leave_id !== leaveId) }))
      return true
    } catch (err: any) {
      set({ error: err.response?.data?.message || "Could not approve — try again" })
      return false
    }
  },

  rejectLeave: async (leaveId, reason) => {
    try {
      await api.post(`/supervisor/reject/${leaveId}`, { reason })
      set((s) => ({ pendingRequests: s.pendingRequests.filter((l) => l.leave_id !== leaveId) }))
      return true
    } catch (err: any) {
      set({ error: err.response?.data?.message || "Failed to reject" })
      return false
    }
  },

  loadApprovedLeaves: async () => {
    try {
      const res = await api.get("/supervisor/approved")
      set({ approvedLeaves: res.data.data })
    } catch (err: any) {
      set({ error: err.response?.data?.message || "Could not load approved leaves" })
    }
  },

  revokeApproval: async (leaveId) => {
    try {
      await api.post(`/supervisor/revoke/${leaveId}`)
      set((s) => ({ approvedLeaves: s.approvedLeaves.filter((l) => l.leave_id !== leaveId) }))
      return true
    } catch (err: any) {
      set({ error: err.response?.data?.message || "Failed to revoke" })
      return false
    }
  },
}))
