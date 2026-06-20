import { supabase } from '@/supabase'
import { useAuthStore } from '@/stores/auth'

/**
 * Base API class wrapping Supabase queries
 * All CRUD operations auto-log to audit_logs
 */
export class BaseApi {
  constructor(tableName) {
    this.table = tableName
  }

  query() { return supabase.from(this.table) }

  async list({ filters = {}, select = '*', order = { column: 'created_at', ascending: false }, page = 1, pageSize = 20 } = {}) {
    let q = this.query().select(select, { count: 'exact' })
    Object.entries(filters).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') q = q.eq(k, v)
    })
    if (order) q = q.order(order.column, { ascending: order.ascending })
    const from = (page - 1) * pageSize
    q = q.range(from, from + pageSize - 1)
    const { data, error, count } = await q
    if (error) throw error
    return { data, total: count, page, pageSize }
  }

  async getById(id, select = '*') {
    const { data, error } = await this.query().select(select).eq('id', id).single()
    if (error) throw error
    return data
  }

  async create(payload) {
    const { data, error } = await this.query().insert(payload).select().single()
    if (error) throw error
    await this._auditLog('CREATE', data.id, null, data)
    return data
  }

  async update(id, payload) {
    const old = await this.getById(id)
    const { data, error } = await this.query().update({ ...payload, updated_at: new Date().toISOString() }).eq('id', id).select().single()
    if (error) throw error
    await this._auditLog('UPDATE', id, old, data)
    return data
  }

  async remove(id) {
    const old = await this.getById(id)
    const { error } = await this.query().delete().eq('id', id)
    if (error) throw error
    await this._auditLog('DELETE', id, old, null)
    return true
  }

  async _auditLog(action, resourceId, oldData, newData) {
    try {
      const auth = useAuthStore()
      await supabase.from('audit_logs').insert({
        user_id: auth.userId,
        action,
        module: this.table,
        resource: this.table,
        resource_id: String(resourceId),
        old_data: oldData,
        new_data: newData
      })
    } catch (e) { /* audit failures should not block main flow */ }
  }
}
