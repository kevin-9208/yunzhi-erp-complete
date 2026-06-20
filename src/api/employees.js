import { BaseApi } from './base'
import { supabase } from '@/supabase'

class EmployeesApi extends BaseApi {
  constructor() { super('employees') }

  async list(params = {}) {
    return super.list({
      ...params,
      select: '*, departments(id,name), positions(id,name), manager:manager_id(id,name)'
    })
  }

  async search(keyword) {
    const { data, error } = await supabase.from('employees')
      .select('id, emp_no, name, dept:departments(name), pos:positions(name)')
      .or(`name.ilike.%${keyword}%,emp_no.ilike.%${keyword}%`)
      .limit(20)
    if (error) throw error
    return data
  }

  async resign(id, resignDate, reason) {
    return this.update(id, { status: 'resigned', resign_date: resignDate, resign_reason: reason })
  }

  async getOrgTree() {
    const { data } = await supabase.from('departments')
      .select('id, name, parent_id, manager:manager_id(name)')
      .eq('status', 'active').order('sort_order')
    return buildTree(data || [])
  }
}

function buildTree(items, parentId = null) {
  return items.filter(i => i.parent_id === parentId).map(item => ({
    ...item,
    children: buildTree(items, item.id)
  }))
}

export const employeesApi = new EmployeesApi()
