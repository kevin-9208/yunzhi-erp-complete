import { defineStore } from 'pinia'
import { supabase, subscribeToNotifications } from '@/supabase'

export const useNotificationStore = defineStore('notification', {
  state: () => ({ list: [], unreadCount: 0, subscription: null }),
  actions: {
    async fetch(userId) {
      const { data } = await supabase.from('notifications')
        .select('*').eq('user_id', userId)
        .order('created_at', { ascending: false }).limit(50)
      this.list = data || []
      this.unreadCount = this.list.filter(n => !n.is_read).length
    },
    subscribe(userId) {
      this.subscription = subscribeToNotifications(userId, n => {
        this.list.unshift(n); this.unreadCount++
      })
    },
    async markAllRead() {
      const ids = this.list.filter(n => !n.is_read).map(n => n.id)
      if (!ids.length) return
      await supabase.from('notifications').update({ is_read: true }).in('id', ids)
      this.list.forEach(n => n.is_read = true); this.unreadCount = 0
    }
  }
})
