import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { Badge } from '@/components/ui/badge'

describe('Badge', () => {
  it('renders with default variant', () => {
    render(<Badge>Default</Badge>)
    const badge = screen.getByText('Default')
    expect(badge).toBeInTheDocument()
    expect(badge.className).toContain('inline-flex')
  })

  it('renders with pending variant', () => {
    render(<Badge variant="pending">Pending</Badge>)
    const badge = screen.getByText('Pending')
    expect(badge).toBeInTheDocument()
  })

  it('renders with approved variant', () => {
    render(<Badge variant="approved">Approved</Badge>)
    const badge = screen.getByText('Approved')
    expect(badge).toBeInTheDocument()
  })

  it('renders with rejected variant', () => {
    render(<Badge variant="rejected">Rejected</Badge>)
    const badge = screen.getByText('Rejected')
    expect(badge).toBeInTheDocument()
  })

  it('renders with custom className', () => {
    render(<Badge className="custom-class">Custom</Badge>)
    const badge = screen.getByText('Custom')
    expect(badge.className).toContain('custom-class')
  })
})
