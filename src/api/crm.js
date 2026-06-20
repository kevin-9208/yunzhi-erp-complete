import { BaseApi } from './base'
import { supabase } from '@/supabase'

class CustomersApi extends BaseApi {
  constructor() { super('customers') }
  async list(params = {}) {
    return super.list({ ...params, select: '*, owner:owner_id(name)' })
  }
  async getTimeline(customerId) {
    const { data } = await supabase.from('follow_records')
      .select('*, user:user_id(name)').eq('customer_id', customerId)
      .order('follow_date', { ascending: false })
    return data
  }
  async addFollow(record) {
    const { data, error } = await supabase.from('follow_records').insert(record).select().single()
    if (error) throw error
    return data
  }
}

class OpportunitiesApi extends BaseApi {
  constructor() { super('opportunities') }
  async list(params = {}) {
    return super.list({ ...params, select: '*, customers(name), owner:owner_id(name)' })
  }
  async getFunnel() {
    const { data } = await supabase.from('opportunities')
      .select('stage, amount').eq('stage', 'won').neq('stage', 'lost')
    return data
  }
}

class SalesOrdersApi extends BaseApi {
  constructor() { super('sales_orders') }
  async list(params = {}) {
    return super.list({ ...params, select: '*, customers(name), items:sales_order_items(*, products(name))' })
  }
  async approve(id) { return this.update(id, { status: 'approved' }) }
  async ship(id) { return this.update(id, { status: 'shipped' }) }
}

export const customersApi = new CustomersApi()
export const opportunitiesApi = new OpportunitiesApi()
export const salesOrdersApi = new SalesOrdersApi()
