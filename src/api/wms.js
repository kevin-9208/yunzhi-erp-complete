import { BaseApi } from './base'
import { supabase } from '@/supabase'

class InventoryApi extends BaseApi {
  constructor() { super('inventory') }
  async list(p = {}) {
    return super.list({ ...p, select: '*, products(sku,name,category_id), warehouses(name)' })
  }
  async getAlerts() {
    const { data } = await supabase.from('inventory')
      .select('*, products(name,sku)').filter('qty', 'lte', supabase.raw('safety_qty'))
    return data
  }
  async transfer(from, to, productId, qty) {
    const { data, error } = await supabase.rpc('transfer_stock', { p_from: from, p_to: to, p_product: productId, p_qty: qty })
    if (error) throw error
    return data
  }
}

class TransactionsApi extends BaseApi {
  constructor() { super('inventory_transactions') }
  async inbound(payload) {
    const { data, error } = await supabase.rpc('process_inbound', payload)
    if (error) throw error
    return data
  }
  async outbound(payload) {
    const { data, error } = await supabase.rpc('process_outbound', payload)
    if (error) throw error
    return data
  }
}

export const inventoryApi = new InventoryApi()
export const transactionsApi = new TransactionsApi()
