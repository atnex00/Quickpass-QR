import axios from "axios"

let _accessToken: string | null = null
let _refreshPromise: Promise<string | null> | null = null
let _onAuthFailure: (() => void) | null = null

export function setAccessToken(token: string | null) {
  _accessToken = token
}

export function getAccessToken(): string | null {
  return _accessToken
}

export function setOnAuthFailure(callback: (() => void) | null) {
  _onAuthFailure = callback
}

const _base = import.meta.env.VITE_API_URL || "/api"

async function refreshAccessToken(): Promise<string | null> {
  if (_refreshPromise) return _refreshPromise

  _refreshPromise = axios
    .post(`${_base}/auth/refresh`, {}, { withCredentials: true })
    .then((res) => res.data?.token || null)
    .catch(() => null)
    .finally(() => {
      _refreshPromise = null
    })

  return _refreshPromise
}

const api = axios.create({
  baseURL: _base,
  headers: { "Content-Type": "application/json" },
  withCredentials: true,
})

api.interceptors.request.use((config) => {
  if (_accessToken) {
    config.headers.Authorization = `Bearer ${_accessToken}`
  }
  return config
})

api.interceptors.response.use(
  (res) => res,
  async (err) => {
    const originalRequest = err.config
    if (err.response?.status === 401 && !originalRequest._retry && originalRequest.url !== "/auth/refresh") {
      originalRequest._retry = true
      const newToken = await refreshAccessToken()
      if (newToken) {
        setAccessToken(newToken)
        originalRequest.headers.Authorization = `Bearer ${newToken}`
        return api(originalRequest)
      }
      setAccessToken(null)
      _onAuthFailure?.()
    }
    return Promise.reject(err)
  }
)

export default api
