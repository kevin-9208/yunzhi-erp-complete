import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: { autoRefreshToken: true, persistSession: true, detectSessionInUrl: true }
})

export const authApi = {
  async signIn(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
    return data
  },
  async signOut() { await supabase.auth.signOut() },
  async getSession() {
    const { data: { session } } = await supabase.auth.getSession()
    return session
  },
  onAuthStateChange(cb) { return supabase.auth.onAuthStateChange(cb) }
}

export function subscribeToNotifications(userId, callback) {
  return supabase.channel('notif:' + userId)
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notifications', filter: 'user_id=eq.' + userId }, p => callback(p.new))
    .subscribe()
}

export const storageApi = {
  async upload(bucket, path, file) {
    const { data, error } = await supabase.storage.from(bucket).upload(path, file, { upsert: true })
    if (error) throw error
    return data
  },
  getPublicUrl(bucket, path) {
    return supabase.storage.from(bucket).getPublicUrl(path).data.publicUrl
  }
}
