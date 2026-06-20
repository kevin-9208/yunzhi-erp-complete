import { BaseApi } from './base'
import { supabase } from '@/supabase'

class ReceivablesApi extends BaseApi {
  constructor() { super('receivables') }
  async list(p = {}) { return super.list({ ...p, select: '*, customers(name), sales_orders(order_no)' }) }
  async getAgingReport() {
    const { data } = await supabase.rpc('get_aging_report')
    return data
  }
}

class PayablesApi extends BaseApi {
  constructor() { super('payables') }
  async list(p = {}) { return super.list({ ...p, select: '*, suppliers(name)' }) }
}

class ExpensesApi extends BaseApi {
  constructor() { super('expense_reports') }
  async list(p = {}) { return super.list({ ...p, select: '*, employees(name), departments(name)' }) }
  async submit(id) { return this.update(id, { status: 'submitted', submit_date: new Date().toISOString() }) }
  async approve(id, userId) { return this.update(id, { status: 'approved', approved_by: userId, approved_at: new Date().toISOString() }) }
  async reject(id, reason) { return this.update(id, { status: 'rejected', reject_reason: reason }) }
}

class LedgerApi extends BaseApi {
  constructor() { super('vouchers') }
  async list(p = {}) { return super.list({ ...p, select: '*, lines:voucher_lines(*, accounts(code,name)), preparer:prepared_by(name)' }) }
  async post(id) { return this.update(id, { status: 'posted', posted_at: new Date().toISOString() }) }
  async getTrialBalance(year, month) {
    const { data } = await supabase.rpc('get_trial_balance', { p_year: year, p_month: month })
    return data
  }
}

export const receivablesApi = new ReceivablesApi()
export const payablesApi = new PayablesApi()
export const expensesApi = new ExpensesApi()
export const ledgerApi = new LedgerApi()
