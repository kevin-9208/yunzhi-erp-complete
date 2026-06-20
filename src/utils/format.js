import dayjs from 'dayjs'

export const fmt = {
  date: (d, f = 'YYYY-MM-DD') => d ? dayjs(d).format(f) : '-',
  datetime: (d) => d ? dayjs(d).format('YYYY-MM-DD HH:mm') : '-',
  money: (v, symbol = '¥') => v !== null && v !== undefined ? `${symbol}${Number(v).toLocaleString('zh-CN', { minimumFractionDigits: 2 })}` : '-',
  percent: (v) => v !== null ? `${Number(v).toFixed(1)}%` : '-',
  number: (v) => v !== null ? Number(v).toLocaleString() : '-',
  fileSize: (bytes) => {
    if (!bytes) return '-'
    const units = ['B','KB','MB','GB']
    let i = 0; let v = bytes
    while (v >= 1024 && i < units.length - 1) { v /= 1024; i++ }
    return `${v.toFixed(1)} ${units[i]}`
  },
  phone: (p) => p ? p.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : '-',
}

export const STATUS_COLORS = {
  active: 'success', resigned: 'danger', suspended: 'warning',
  draft: 'info', pending: 'warning', approved: 'success',
  processing: '', shipped: '', completed: 'success', cancelled: 'danger',
  normal: 'success', warning: 'warning', shortage: 'danger',
}

export function statusType(status) { return STATUS_COLORS[status] || 'info' }
