import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useAuthStore } from '@/stores/authStore'
import api from '@/lib/api'
import type { Employee } from '@/types'

vi.mock('@/lib/api', () => ({
  default: {
    post: vi.fn(),
    get: vi.fn(),
    put: vi.fn(),
  },
  setAccessToken: vi.fn(),
  getAccessToken: vi.fn(),
  setOnAuthFailure: vi.fn(),
  getErrorMessage: (err: unknown, fallback: string) => {
    const data = (err as { response?: { data?: { message?: string } } }).response?.data
    return data?.message || (err as { message?: string }).message || fallback
  },
}))

vi.mock('@/stores/themeStore', () => ({
  rehydrateTheme: vi.fn(),
}))

const { resetLeave, resetScan } = vi.hoisted(() => ({ resetLeave: vi.fn(), resetScan: vi.fn() }))

vi.mock('@/stores/leaveStore', () => ({
  useLeaveStore: { getState: () => ({ reset: resetLeave }) },
}))

vi.mock('@/stores/scanStore', () => ({
  useScanStore: { getState: () => ({ reset: resetScan }) },
}))

const { setAccessToken, getAccessToken } = await import('@/lib/api')

const apiMock = api as unknown as {
  post: ReturnType<typeof vi.fn>
  get: ReturnType<typeof vi.fn>
  put: ReturnType<typeof vi.fn>
}
const getAccessTokenMock = getAccessToken as unknown as ReturnType<typeof vi.fn>

function makeUser(overrides: Partial<Employee> = {}): Employee {
  return {
    employee_id: '000001',
    full_name: 'James Wilson',
    position: 'Staff',
    department_id: 'DEPT1',
    department_name: 'TSD',
    email: 'james@example.com',
    is_supervisor: false,
    is_admin: false,
    is_security: false,
    is_active: true,
    profile_photo: null,
    hire_date: null,
    ...overrides,
  }
}

describe('authStore', () => {
  beforeEach(() => {
    useAuthStore.setState({
      user: null,
      isAuthenticated: false,
      isLoading: true,
      error: null,
    })
    vi.clearAllMocks()
  })

  it('starts with loading state', () => {
    const state = useAuthStore.getState()
    expect(state.isLoading).toBe(true)
    expect(state.isAuthenticated).toBe(false)
    expect(state.user).toBeNull()
  })

  it('login succeeds with valid credentials', async () => {
    const mockUser = makeUser()
    apiMock.post.mockResolvedValueOnce({
      data: { success: true, token: 'mock-token', user: mockUser },
    })

    const result = await useAuthStore.getState().login('000001', 'pass1234')
    const state = useAuthStore.getState()

    expect(result).toBe(true)
    expect(state.isAuthenticated).toBe(true)
    expect(state.user).toEqual(mockUser)
    expect(state.isLoading).toBe(false)
    expect(setAccessToken).toHaveBeenCalledWith('mock-token')
  })

  it('login returns false on API error', async () => {
    apiMock.post.mockRejectedValueOnce({
      response: { data: { message: 'Invalid credentials' } },
    })

    const result = await useAuthStore.getState().login('000001', 'wrong')
    const state = useAuthStore.getState()

    expect(result).toBe(false)
    expect(state.isAuthenticated).toBe(false)
    expect(state.error).toBe('Invalid credentials')
  })

  it('logout clears auth state', async () => {
    useAuthStore.setState({ user: makeUser(), isAuthenticated: true })

    await useAuthStore.getState().logout()
    const state = useAuthStore.getState()

    expect(state.user).toBeNull()
    expect(state.isAuthenticated).toBe(false)
    expect(setAccessToken).toHaveBeenCalledWith(null)
    expect(resetLeave).toHaveBeenCalled()
    expect(resetScan).toHaveBeenCalled()
  })

  it('loadUser refreshes token when no access token exists', async () => {
    getAccessTokenMock.mockReturnValue(null)
    apiMock.post.mockResolvedValueOnce({
      data: { token: 'refreshed-token' },
    })
    const mockProfile = makeUser()
    apiMock.get.mockResolvedValueOnce({ data: { data: mockProfile } })

    await useAuthStore.getState().loadUser()
    const state = useAuthStore.getState()

    expect(state.isAuthenticated).toBe(true)
    expect(state.user).toEqual(mockProfile)
    expect(setAccessToken).toHaveBeenCalledWith('refreshed-token')
  })

  it('updateProfile updates user data', async () => {
    useAuthStore.setState({ user: makeUser() })
    apiMock.put.mockResolvedValueOnce({
      data: { data: { full_name: 'James Updated' } },
    })

    const result = await useAuthStore.getState().updateProfile({ full_name: 'James Updated' })
    const state = useAuthStore.getState()

    expect(result).toBe(true)
    expect(state.user?.full_name).toBe('James Updated')
  })
})
