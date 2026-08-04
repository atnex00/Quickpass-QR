import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useScanStore } from '@/stores/scanStore'
import api from '@/lib/api'

vi.mock('@/lib/api', () => ({
  default: {
    get: vi.fn(),
    post: vi.fn(),
  },
}))

const apiMock = api as unknown as {
  get: ReturnType<typeof vi.fn>
  post: ReturnType<typeof vi.fn>
}

describe('scanStore', () => {
  beforeEach(() => {
    useScanStore.setState({
      isLoading: false,
      error: null,
      lastResult: null,
      history: [],
      historyLoading: false,
    })
    vi.clearAllMocks()
  })

  it('validateScan posts QR data and stores result on success', async () => {
    const result = { success: true, message: 'Valid QR', data: { leave_id: 'LV-001' } }
    apiMock.post.mockResolvedValueOnce({ data: result })

    const ok = await useScanStore.getState().validateScan('qr-data-string')
    const state = useScanStore.getState()

    expect(ok).toBe(true)
    expect(apiMock.post).toHaveBeenCalledWith('/scan/validate', { qr_data: 'qr-data-string' })
    expect(state.lastResult).toEqual(result)
    expect(state.isLoading).toBe(false)
  })

  it('validateScan stores error on failure', async () => {
    apiMock.post.mockRejectedValueOnce({
      response: { status: 400, data: { message: 'Invalid QR code' } },
    })

    const ok = await useScanStore.getState().validateScan('bad-data')
    const state = useScanStore.getState()

    expect(ok).toBe(false)
    expect(state.error).toBe('Invalid QR code')
    expect(state.lastResult).toEqual({ success: false, message: 'Invalid QR code' })
  })

  it('validateScan stores generic message when no response error text', async () => {
    apiMock.post.mockRejectedValueOnce(new Error('Network Error'))

    await useScanStore.getState().validateScan('bad-data')

    expect(useScanStore.getState().error).toBe('Network Error')
  })

  it('loadHistory fetches scan history', async () => {
    const history = [{ id: 1, qr_data: 'abc' }]
    apiMock.get.mockResolvedValueOnce({ data: { data: history } })

    await useScanStore.getState().loadHistory()

    expect(useScanStore.getState().history).toEqual(history)
    expect(useScanStore.getState().historyLoading).toBe(false)
  })

  it('loadHistory sets loading false on error', async () => {
    apiMock.get.mockRejectedValueOnce(new Error('fail'))

    await useScanStore.getState().loadHistory()

    expect(useScanStore.getState().historyLoading).toBe(false)
  })

  it('clearResult resets last result and error', () => {
    useScanStore.setState({ lastResult: { success: true }, error: 'some error' })

    useScanStore.getState().clearResult()

    expect(useScanStore.getState().lastResult).toBeNull()
    expect(useScanStore.getState().error).toBeNull()
  })
})
