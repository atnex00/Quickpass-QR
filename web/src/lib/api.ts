import axios from "axios"
import Cookies from "js-cookie"

const api = axios.create({
  baseURL: "/api",
  headers: { "Content-Type": "application/json" },
})

api.interceptors.request.use((config) => {
  const token = Cookies.get("quickpass_token")
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      Cookies.remove("quickpass_token")
      Cookies.remove("quickpass_user")
      window.location.href = "/login"
    }
    return Promise.reject(err)
  }
)

export default api
