import { supabase } from '@/supabase'

export const workflowApi = {
  async getTemplates() {
    const { data } = await supabase.from('workflow_templates').select('*').eq('is_active', true)
    return data
  },
  async getInstance(id) {
    const { data } = await supabase.from('workflow_instances')
      .select('*, template:workflow_templates(*), approvals:workflow_approvals(*, approver:approver_id(name))')
      .eq('id', id).single()
    return data
  },
  async submit(templateId, formData, refType, refId) {
    const { data, error } = await supabase.rpc('submit_workflow', {
      p_template_id: templateId, p_form_data: formData, p_ref_type: refType, p_ref_id: refId
    })
    if (error) throw error
    return data
  },
  async approve(instanceId, nodeIndex, comment) {
    const { data, error } = await supabase.rpc('approve_workflow', {
      p_instance_id: instanceId, p_node_index: nodeIndex, p_action: 'approve', p_comment: comment
    })
    if (error) throw error
    return data
  },
  async reject(instanceId, nodeIndex, comment) {
    const { data, error } = await supabase.rpc('reject_workflow', {
      p_instance_id: instanceId, p_node_index: nodeIndex, p_action: 'reject', p_comment: comment
    })
    if (error) throw error
    return data
  },
  async myPending() {
    const { data } = await supabase.from('workflow_instances')
      .select('*, template:workflow_templates(name,type), applicant:applicant_id(name)')
      .eq('status', 'pending').order('created_at', { ascending: false })
    return data
  }
}
