import { create } from "zustand"
import type { LeaveRequest } from "@/types"
import api, { getErrorMessage } from "@/lib/api"

interface LeaveState {
  history: LeaveRequest[]
  activeLeave: LeaveRequest | null
  pendingRequests: LeaveRequest[]
  approvedLeaves: LeaveRequest[]
  isLoading: boolean
  error: string | null
  loadHistory: (status?: string) => Promise<void>
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
  reset: () => void
}

export const useLeaveStore = create<LeaveState>((set) => ({
  history: [],
  activeLeave: null,
  pendingRequests: [],
  approvedLeaves: [],
  isLoading: false,
  error: null,

  loadHistory: async (status) => {
    set({ isLoading: true, error: null })
    try {
      const params: { status?: string } = {}
      if (status) params.status = status
      const res = await api.get("/leave/history", { params })
      set({ history: res.data.data, isLoading: false })
    } catch (err) {
      set({ error: getErrorMessage(err, "Could not load history — refresh the page"), isLoading: false })
    }
  },

  loadActiveLeave: async () => {
    set({ isLoading: true })
    try {
      const res = await api.get("/leave/active")
      set({ activeLeave: res.data.data, isLoading: false })
    } catch {
      set({ activeLeave: null, isLoading: false })
    }
  },

  submitLeave: async (data) => {
    set({ isLoading: true, error: null })
    try {
      const res = await api.post("/leave/request", data)
      const newLeave: LeaveRequest = res.data.data
      set((s) => ({ history: [newLeave, ...s.history], isLoading: false }))
      return true
    } catch (err) {
      set({ error: getErrorMessage(err, "Could not submit leave — check the form and try again"), isLoading: false })
      return false
    }
  },

  loadPendingRequests: async () => {
    set({ isLoading: true, error: null })
    try {
      const res = await api.get("/supervisor/pending")
      set({ pendingRequests: res.data.data, isLoading: false })
    } catch (err) {
      set({ error: getErrorMessage(err, "Could not load pending requests"), isLoading: false })
    }
  },

  approveLeave: async (leaveId) => {
    try {
      await api.post(`/supervisor/approve/${leaveId}`)
      set((s) => ({ pendingRequests: s.pendingRequests.filter((l) => l.leave_id !== leaveId) }))
      return true
    } catch (err) {
      set({ error: getErrorMessage(err, "Could not approve — try again") })
      return false
    }
  },

  rejectLeave: async (leaveId, reason) => {
    try {
      await api.post(`/supervisor/reject/${leaveId}`, { reason })
      set((s) => ({ pendingRequests: s.pendingRequests.filter((l) => l.leave_id !== leaveId) }))
      return true
    } catch (err) {
      set({ error: getErrorMessage(err, "Failed to reject") })
      return false
    }
  },

  loadApprovedLeaves: async () => {
    try {
      const res = await api.get("/supervisor/approved")
      set({ approvedLeaves: res.data.data })
    } catch (err) {
      set({ error: getErrorMessage(err, "Could not load approved leaves") })
    }
  },

  revokeApproval: async (leaveId) => {
    try {
      await api.post(`/supervisor/revoke/${leaveId}`)
      set((s) => ({ approvedLeaves: s.approvedLeaves.filter((l) => l.leave_id !== leaveId) }))
      return true
    } catch (err) {
      set({ error: getErrorMessage(err, "Failed to revoke") })
      return false
    }
  },

  reset: () => set({ history: [], activeLeave: null, pendingRequests: [], approvedLeaves: [], isLoading: false, error: null }),
}))
