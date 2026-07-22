import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useLeaveStore } from '@/stores/leaveStore'
import api from '@/lib/api'

vi.mock('@/lib/api', () => ({
  default: {
    get: vi.fn(),
    post: vi.fn(),
  },
}))

describe('leaveStore', () => {
  beforeEach(() => {
    useLeaveStore.setState({
      history: [],
      activeLeave: null,
      pendingRequests: [],
      approvedLeaves: [],
      isLoading: false,
      error: null,
    })
    vi.clearAllMocks()
  })

  it('loadHistory fetches and sets history', async () => {
    const leaves = [{ leave_id: 'LV-001', status: 'approved' }]
    ;(api.get as any).mockResolvedValueOnce({ data: { data: leaves } })

    await useLeaveStore.getState().loadHistory()
    const state = useLeaveStore.getState()

    expect(state.history).toEqual(leaves)
    expect(state.isLoading).toBe(false)
  })

  it('loadHistory with status filter passes params', async () => {
    ;(api.get as any).mockResolvedValueOnce({ data: { data: [] } })

    await useLeaveStore.getState().loadHistory('pending')

    expect(api.get).toHaveBeenCalledWith('/leave/history', { params: { status: 'pending' } })
  })

  it('loadHistory sets error on failure', async () => {
    ;(api.get as any).mockRejectedValueOnce({
      response: { data: { message: 'Server error' } },
    })

    await useLeaveStore.getState().loadHistory()
    const state = useLeaveStore.getState()

    expect(state.error).toBe('Server error')
    expect(state.isLoading).toBe(false)
  })

  it('loadActiveLeave sets active leave', async () => {
    const leave = { leave_id: 'LV-001', status: 'approved' }
    ;(api.get as any).mockResolvedValueOnce({ data: { data: leave } })

    await useLeaveStore.getState().loadActiveLeave()

    expect(useLeaveStore.getState().activeLeave).toEqual(leave)
  })

  it('loadActiveLeave sets null on 404', async () => {
    ;(api.get as any).mockRejectedValueOnce(new Error('Not found'))

    await useLeaveStore.getState().loadActiveLeave()

    expect(useLeaveStore.getState().activeLeave).toBeNull()
  })

  it('submitLeave posts data and prepends to history', async () => {
    const newLeave = { leave_id: 'LV-002', status: 'pending' }
    ;(api.post as any).mockResolvedValueOnce({ data: { data: newLeave } })
    useLeaveStore.setState({ history: [{ leave_id: 'LV-001' }] })

    const result = await useLeaveStore.getState().submitLeave({
      leave_date: '2026-07-22', start_time: '09:00', end_time: '17:00', reason: 'Sick',
    })

    expect(result).toBe(true)
    expect(api.post).toHaveBeenCalledWith('/leave/request', {
      leave_date: '2026-07-22', start_time: '09:00', end_time: '17:00', reason: 'Sick',
    })
    expect(useLeaveStore.getState().history[0]).toEqual(newLeave)
  })

  it('submitLeave returns false on error', async () => {
    ;(api.post as any).mockRejectedValueOnce({
      response: { data: { message: 'Time conflict' } },
    })

    const result = await useLeaveStore.getState().submitLeave({
      leave_date: '2026-07-22', start_time: '09:00', end_time: '17:00', reason: 'Sick',
    })

    expect(result).toBe(false)
    expect(useLeaveStore.getState().error).toBe('Time conflict')
  })

  it('loadPendingRequests fetches pending requests', async () => {
    const requests = [{ leave_id: 'LV-003', status: 'pending' }]
    ;(api.get as any).mockResolvedValueOnce({ data: { data: requests } })

    await useLeaveStore.getState().loadPendingRequests()

    expect(useLeaveStore.getState().pendingRequests).toEqual(requests)
  })

  it('approveLeave posts approval and removes from pending', async () => {
    ;(api.post as any).mockResolvedValueOnce({})
    useLeaveStore.setState({ pendingRequests: [{ leave_id: 'LV-001' }, { leave_id: 'LV-002' }] })

    const result = await useLeaveStore.getState().approveLeave('LV-001')

    expect(result).toBe(true)
    expect(api.post).toHaveBeenCalledWith('/supervisor/approve/LV-001')
    expect(useLeaveStore.getState().pendingRequests).toEqual([{ leave_id: 'LV-002' }])
  })

  it('rejectLeave posts rejection with reason', async () => {
    ;(api.post as any).mockResolvedValueOnce({})
    useLeaveStore.setState({ pendingRequests: [{ leave_id: 'LV-001' }] })

    const result = await useLeaveStore.getState().rejectLeave('LV-001', 'Not approved')

    expect(result).toBe(true)
    expect(api.post).toHaveBeenCalledWith('/supervisor/reject/LV-001', { reason: 'Not approved' })
    expect(useLeaveStore.getState().pendingRequests).toHaveLength(0)
  })

  it('loadApprovedLeaves fetches approved leaves', async () => {
    const leaves = [{ leave_id: 'LV-004', status: 'approved' }]
    ;(api.get as any).mockResolvedValueOnce({ data: { data: leaves } })

    await useLeaveStore.getState().loadApprovedLeaves()

    expect(useLeaveStore.getState().approvedLeaves).toEqual(leaves)
  })

  it('revokeApproval posts revoke and removes from approved', async () => {
    ;(api.post as any).mockResolvedValueOnce({})
    useLeaveStore.setState({ approvedLeaves: [{ leave_id: 'LV-001' }] })

    const result = await useLeaveStore.getState().revokeApproval('LV-001')

    expect(result).toBe(true)
    expect(api.post).toHaveBeenCalledWith('/supervisor/revoke/LV-001')
    expect(useLeaveStore.getState().approvedLeaves).toHaveLength(0)
  })
})
