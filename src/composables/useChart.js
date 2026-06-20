import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'

const darkTheme = {
  backgroundColor: 'transparent',
  textStyle: { color: '#9ba3b8' },
  title: { textStyle: { color: '#e8eaf0' } },
  legend: { textStyle: { color: '#9ba3b8' } },
  tooltip: {
    backgroundColor: '#1e2535',
    borderColor: '#2a3548',
    textStyle: { color: '#e8eaf0' }
  },
  grid: { borderColor: '#2a3548' },
  categoryAxis: { axisLine: { lineStyle: { color: '#2a3548' } }, axisTick: { lineStyle: { color: '#2a3548' } }, axisLabel: { color: '#6b7591' }, splitLine: { lineStyle: { color: '#2a3548' } } },
  valueAxis: { axisLabel: { color: '#6b7591' }, splitLine: { lineStyle: { color: '#2a3548' } } }
}

export function useChart(elRef, options) {
  const chart = ref(null)

  function init() {
    if (!elRef.value) return
    chart.value = echarts.init(elRef.value, null, { renderer: 'canvas' })
    chart.value.setOption({ ...darkTheme, ...options })
  }

  function update(opts) {
    if (!chart.value) return
    chart.value.setOption(opts, { notMerge: false, lazyUpdate: true })
  }

  function resize() { chart.value?.resize() }

  onMounted(() => nextTick(init))
  onUnmounted(() => { chart.value?.dispose(); chart.value = null })

  window.addEventListener('resize', resize)
  onUnmounted(() => window.removeEventListener('resize', resize))

  return { chart, update, resize }
}

// Color palette
export const COLORS = ['#4f8ef7','#22c55e','#a855f7','#f59e0b','#14b8a6','#f97316','#ef4444','#6b7591']
