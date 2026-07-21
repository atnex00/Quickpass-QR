import { describe, it, expect, beforeEach } from 'vitest'
import { useThemeStore } from '@/stores/themeStore'

describe('themeStore', () => {
  beforeEach(() => {
    useThemeStore.setState({ theme: 'system' })
  })

  it('defaults to system theme', () => {
    const state = useThemeStore.getState()
    expect(state.theme).toBe('system')
  })

  it('setTheme updates the theme', () => {
    useThemeStore.getState().setTheme('dark')
    expect(useThemeStore.getState().theme).toBe('dark')

    useThemeStore.getState().setTheme('light')
    expect(useThemeStore.getState().theme).toBe('light')
  })

  it('resolved returns system preference when theme is system', () => {
    useThemeStore.getState().setTheme('system')
    const resolved = useThemeStore.getState().resolved()
    expect(['light', 'dark']).toContain(resolved)
  })

  it('resolved returns theme when not system', () => {
    useThemeStore.getState().setTheme('dark')
    expect(useThemeStore.getState().resolved()).toBe('dark')

    useThemeStore.getState().setTheme('light')
    expect(useThemeStore.getState().resolved()).toBe('light')
  })
})
