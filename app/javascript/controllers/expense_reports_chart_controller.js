// app/javascript/controllers/expense_reports_chart_controller.js
import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  static targets = ["dailyExpensesChart", "categoryChart"]

  connect() {
    this.initDailyExpensesChart()
    this.initCategoryChart()
  }

  initDailyExpensesChart() {
    if (!this.hasDailyExpensesChartTarget) return

    const canvas = this.dailyExpensesChartTarget
    const data = JSON.parse(canvas.dataset.chartData || '[]')

    const labels = data.map(item => item.date)
    const amounts = data.map(item => item.amount)

    new Chart(canvas, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: 'Daily Expenses',
          data: amounts,
          borderColor: '#d32f2f',
          backgroundColor: 'rgba(211, 47, 47, 0.1)',
          fill: true,
          tension: 0.3,
          pointBackgroundColor: '#d32f2f',
          pointBorderColor: '#fff',
          pointBorderWidth: 2,
          pointRadius: 4,
          pointHoverRadius: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                return '₦' + context.parsed.y.toLocaleString()
              }
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: function(value) {
                return '₦' + value.toLocaleString()
              }
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.05)'
            }
          },
          x: {
            grid: {
              display: false
            }
          }
        }
      }
    })
  }

  initCategoryChart() {
    if (!this.hasCategoryChartTarget) return

    const canvas = this.categoryChartTarget
    const data = JSON.parse(canvas.dataset.chartData || '[]')

    const labels = data.map(item => item.category)
    const amounts = data.map(item => item.amount)

    const colors = [
      '#d32f2f',
      '#1976d2',
      '#388e3c',
      '#f57c00',
      '#7b1fa2',
      '#0097a7',
      '#c2185b',
      '#512da8',
      '#00796b',
      '#afb42b'
    ]

    new Chart(canvas, {
      type: 'doughnut',
      data: {
        labels: labels,
        datasets: [{
          data: amounts,
          backgroundColor: colors.slice(0, labels.length),
          borderWidth: 2,
          borderColor: '#fff'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'right',
            labels: {
              boxWidth: 12,
              padding: 15,
              font: {
                size: 11
              }
            }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const total = context.dataset.data.reduce((a, b) => a + b, 0)
                const percentage = ((context.parsed / total) * 100).toFixed(1)
                return context.label + ': ₦' + context.parsed.toLocaleString() + ' (' + percentage + '%)'
              }
            }
          }
        }
      }
    })
  }
}
