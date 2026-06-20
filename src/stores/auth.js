import { defineStore } from 'pinia'
import { authApi, supabase } from '@/supabase'

export const useAuthStore = defineStore('auth', {
  state: () => ({ user: null, profile: null, session: null, loading: false, initialized: false }),
  getters: {
    isAuthenticated: s => !!s.session,
    userId: s => s.user?.id,
    userName: s => s.profile?.name || s.user?.email,
    userRole: s => s.profile?.roles?.name || 'employee',
    isSuperAdmin: s => s.profile?.roles?.name === 'super_admin'
  },
  actions: {
    async initAuth() {
      this.loading = true
      try {
        const session = await authApi.getSession()
        if (session) { this.session = session; this.user = session.user; await this.fetchProfile() }
        authApi.onAuthStateChange(async (event, session) => {
          this.session = session; this.user = session?.user || null
          if (event === 'SIGNED_IN') await this.fetchProfile()
          else if (event === 'SIGNED_OUT') this.profile = null
        })
      } finally { this.loading = false; this.initialized = true }
    },
    async fetchProfile() {
      if (!this.user) return
      const { data } = await supabase.from('users')
        .select('*, roles(*), departments(id,name), positions(id,name)')
        .eq('id', this.user.id).single()
      this.profile = data
    },
    async signIn(email, password) {
      this.loading = true
      try {
        const data = await authApi.signIn(email, password)
        this.session = data.session; this.user = data.user
        await this.fetchProfile()
      } finally { this.loading = false }
    },
    async signOut() {
      await authApi.signOut()
      this.$reset()
    },
    hasPermission(module, action = 'read') {
      if (this.isSuperAdmin) return true
      return this.profile?.roles?.permissions?.some(p => p.module === module && p.action === action) ?? false
    }
  }
})
