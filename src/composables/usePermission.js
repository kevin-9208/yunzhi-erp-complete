import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

export function usePermission() {
  const authStore = useAuthStore()

  function can(module, action = 'read') {
    return authStore.hasPermission(module, action)
  }

  const isAdmin = computed(() => authStore.isSuperAdmin || authStore.userRole === 'admin')
  const isFinance = computed(() => isAdmin.value || authStore.userRole === 'finance')
  const isSales = computed(() => isAdmin.value || authStore.userRole === 'sales')
  const isHR = computed(() => isAdmin.value || authStore.userRole === 'hr')
  const isWarehouse = computed(() => isAdmin.value || authStore.userRole === 'warehouse')

  return { can, isAdmin, isFinance, isSales, isHR, isWarehouse }
}
