import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import { setAccessToken, getAccessToken, setOnAuthFailure } from '@/lib/api'

const { holder } = vi.hoisted(() => ({
  holder: {
    value: undefined as unknown as {
      interceptors: { request: { use: ReturnType<typeof vi.fn> }; response: { use: ReturnType<typeof vi.fn> } }
      post: ReturnType<typeof vi.fn>
      get: ReturnType<typeof vi.fn>
      put: ReturnType<typeof vi.fn>
    },
  },
}))

const callCreatedInstance = () => holder.value

vi.mock('axios', () => {
  const mockAxiosInstance = vi.fn(() => Promise.resolve({ data: { retried: true } })) as unknown as typeof holder.value
  mockAxiosInstance.interceptors = {
    request: { use: vi.fn() },
    response: { use: vi.fn() },
  }
  mockAxiosInstance.post = vi.fn()
  mockAxiosInstance.get = vi.fn()
  mockAxiosInstance.put = vi.fn()
  holder.value = mockAxiosInstance
  const mockAxios = {
    create: vi.fn(() => mockAxiosInstance),
    post: vi.fn(),
  }
  return { default: mockAxios }
})

describe('api client', () => {
  beforeEach(() => {
    setAccessToken(null)
    setOnAuthFailure(null)
    vi.mocked(axios.post).mockClear()
    ;(holder.value as unknown as ReturnType<typeof vi.fn>).mockClear()
  })

  it('setAccessToken and getAccessToken work', () => {
    expect(getAccessToken()).toBeNull()
    setAccessToken('test-token')
    expect(getAccessToken()).toBe('test-token')
    setAccessToken(null)
    expect(getAccessToken()).toBeNull()
  })

  it('configures base URL and credentials', () => {
    expect(axios.create).toHaveBeenCalledWith({
      baseURL: '/api',
      headers: { 'Content-Type': 'application/json' },
      withCredentials: true,
    })
  })

  it('registers request interceptor', () => {
    expect(callCreatedInstance().interceptors.request.use).toHaveBeenCalled()
  })

  it('registers response interceptor', () => {
    expect(callCreatedInstance().interceptors.response.use).toHaveBeenCalled()
  })

  it('adds the access token to requests when set', () => {
    const onFulfilled = (callCreatedInstance().interceptors.request.use as unknown as ReturnType<typeof vi.fn>).mock.calls[0][0]
    setAccessToken('tok-1')
    const config = onFulfilled({ headers: {} })
    expect(config.headers.Authorization).toBe('Bearer tok-1')
  })

  it('retries the original request after a successful 401 refresh', async () => {
    const onRejected = (callCreatedInstance().interceptors.response.use as unknown as ReturnType<typeof vi.fn>).mock.calls[0][1]
    vi.mocked(axios.post).mockResolvedValueOnce({ data: { token: 'fresh-token' } })

    const originalRequest: { url: string; _retry: boolean; headers: Record<string, string> } = { url: '/leave/history', _retry: false, headers: {} }
    await onRejected({ config: originalRequest, response: { status: 401 } })

    expect(axios.post).toHaveBeenCalledWith('/api/auth/refresh', {}, { withCredentials: true })
    expect(getAccessToken()).toBe('fresh-token')
    expect(originalRequest._retry).toBe(true)
    expect(originalRequest.headers.Authorization).toBe('Bearer fresh-token')
    expect((callCreatedInstance() as unknown as ReturnType<typeof vi.fn>)).toHaveBeenCalledWith(originalRequest)
  })

  it('signals auth failure when refresh itself fails', async () => {
    const onRejected = (callCreatedInstance().interceptors.response.use as unknown as ReturnType<typeof vi.fn>).mock.calls[0][1]
    vi.mocked(axios.post).mockRejectedValueOnce(new Error('network down'))
    const onAuthFailure = vi.fn()
    setOnAuthFailure(onAuthFailure)

    await expect(
      onRejected({ config: { url: '/leave/history', _retry: false, headers: {} }, response: { status: 401 } })
    ).rejects.toBeTruthy()

    expect(getAccessToken()).toBeNull()
    expect(onAuthFailure).toHaveBeenCalledTimes(1)
  })

  it('never refreshes when the failed request is the refresh call itself', async () => {
    const onRejected = (callCreatedInstance().interceptors.response.use as unknown as ReturnType<typeof vi.fn>).mock.calls[0][1]

    await expect(
      onRejected({ config: { url: '/auth/refresh', _retry: false, headers: {} }, response: { status: 401 } })
    ).rejects.toBeTruthy()

    expect(axios.post).not.toHaveBeenCalled()
  })
})
