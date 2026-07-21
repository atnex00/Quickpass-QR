import { describe, it, expect, beforeEach, vi } from 'vitest'
import { useAuthStore } from '@/stores/authStore'
import api from '@/lib/api'

vi.mock('@/lib/api', () => ({
  default: {
    post: vi.fn(),
    get: vi.fn(),
    put: vi.fn(),
  },
  setAccessToken: vi.fn(),
  getAccessToken: vi.fn(),
  setOnAuthFailure: vi.fn(),
}))

vi.mock('@/stores/themeStore', () => ({
  rehydrateTheme: vi.fn(),
}))

const { setAccessToken, getAccessToken } = await import('@/lib/api')

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
    const mockUser = { employee_id: '000001', full_name: 'Alice Chen' }
    ;(api.post as any).mockResolvedValueOnce({
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
    ;(api.post as any).mockRejectedValueOnce({
      response: { data: { message: 'Invalid credentials' } },
    })

    const result = await useAuthStore.getState().login('000001', 'wrong')
    const state = useAuthStore.getState()

    expect(result).toBe(false)
    expect(state.isAuthenticated).toBe(false)
    expect(state.error).toBe('Invalid credentials')
  })

  it('logout clears auth state', async () => {
    useAuthStore.setState({ user: { employee_id: '000001' } as any, isAuthenticated: true })

    await useAuthStore.getState().logout()
    const state = useAuthStore.getState()

    expect(state.user).toBeNull()
    expect(state.isAuthenticated).toBe(false)
    expect(setAccessToken).toHaveBeenCalledWith(null)
  })

  it('loadUser refreshes token when no access token exists', async () => {
    ;(getAccessToken as any).mockReturnValue(null)
    ;(api.post as any).mockResolvedValueOnce({
      data: { token: 'refreshed-token' },
    })
    const mockProfile = { data: { employee_id: '000001', full_name: 'Alice Chen' } }
    ;(api.get as any).mockResolvedValueOnce({ data: { data: mockProfile } })

    await useAuthStore.getState().loadUser()
    const state = useAuthStore.getState()

    expect(state.isAuthenticated).toBe(true)
    expect(state.user).toEqual(mockProfile)
    expect(setAccessToken).toHaveBeenCalledWith('refreshed-token')
  })

  it('updateProfile updates user data', async () => {
    const existingUser = { employee_id: '000001', full_name: 'Alice' }
    useAuthStore.setState({ user: existingUser as any })
    ;(api.put as any).mockResolvedValueOnce({
      data: { data: { full_name: 'Alice Updated' } },
    })

    const result = await useAuthStore.getState().updateProfile({ full_name: 'Alice Updated' })
    const state = useAuthStore.getState()

    expect(result).toBe(true)
    expect(state.user?.full_name).toBe('Alice Updated')
  })
})
