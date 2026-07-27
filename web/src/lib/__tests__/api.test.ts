import { describe, it, expect, beforeEach, vi } from 'vitest'
import axios from 'axios'
import api, { setAccessToken, getAccessToken, setOnAuthFailure } from '@/lib/api'

vi.mock('axios', () => {
  const mockAxiosInstance = {
    interceptors: {
      request: { use: vi.fn() },
      response: { use: vi.fn() },
    },
    post: vi.fn(),
    get: vi.fn(),
    put: vi.fn(),
  }
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
    const createMock = (axios.create as any).mock.results[0].value
    expect(createMock.interceptors.request.use).toHaveBeenCalled()
  })

  it('registers response interceptor', () => {
    const createMock = (axios.create as any).mock.results[0].value
    expect(createMock.interceptors.response.use).toHaveBeenCalled()
  })
})
